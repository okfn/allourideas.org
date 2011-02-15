class MungeAndNotifyJob < Struct.new(:earl_id, :type, :email, :photocracy, :redis_key)

  def on_permanent_failure
    IdeaMailer.deliver_export_failed(['errors@allourideas.org', email], photocracy)
  end

  # munges CSV file generated by pairwise to augment or remove the CSV
  # also notifies the user that their file is ready
  def perform
    SiteConfig.set_pairwise_credentials(photocracy)
    earl = Earl.find(earl_id)

    # delayed job doesn't like passing the user as parameter
    # so we do this manually
    current_user = User.find_by_email(email)

    r = Redis.new(:host => REDIS_CONFIG['hostname'])

    thekey, zlibcsv = r.blpop(redis_key, (60*5).to_s) # Timeout - 5 minutes

    r.del(redis_key) # client is responsible for deleting key

    zstream = Zlib::Inflate.new
    csvdata = zstream.inflate(zlibcsv)
    zstream.finish
    zstream.close

    #Caching these to prevent repeated lookups for the same session, Hackish, but should be fine for background job
    sessions = {}
    url_aliases = {}

    # instead of building up entire CSV and then inserting into DB
    # update CSV data by concatenating current data with bunches
    # of rows at a time.  This is a temporary holder of our batches.
    rows = []

    num_slugs = earl.slugs.size
    export = Export.create(:name => redis_key, :data => '')

    modified_csv = FasterCSV.generate do |csv|
      FasterCSV.parse(csvdata, {:headers => :first_row, :return_headers => true}) do |row|

        if row.header_row?
          if photocracy
            if type == 'votes'
              row << ['Winner Photo Name', 'Winner Photo Name']
              row << ['Loser Photo Name', 'Loser Photo Name']
            elsif type == 'non_votes'
              row << ['Left Photo Name', 'Left Photo Name']
              row << ['Right Photo Name', 'Right Photo Name']
            elsif type == 'ideas'
              row << ['Photo Name', 'Photo Name']
            end
          end

          case type
            when "votes", "non_votes"
              #We need this to look up SessionInfos, but the user doesn't need to see it
              row.delete('Session Identifier')

              row << ['Hashed IP Address', 'Hashed IP Address']
              row << ['URL Alias', 'URL Alias']
              if current_user.admin?
                #row << ['Geolocation Info', 'Geolocation Info']
              end
          end
          csv << row
          rows << row.to_csv
        else
          if photocracy
            if    type == 'votes'
              p1 = Photo.find_by_id(row['Winner Text'])
              p2 = Photo.find_by_id(row['Loser Text'])
              row << [ 'Winner Photo Name', p1 ? p1.photo_name : 'NA' ]
              row << [ 'Loser Photo Name',  p2 ? p2.photo_name : 'NA' ]
            elsif type == 'non_votes'
              p1 = Photo.find_by_id(row['Left Choice Text'])
              p2 = Photo.find_by_id(row['Right Choice Text'])
              row << [ 'Left Photo Name',  p1 ? p1.photo_name : 'NA' ]
              row << [ 'Right Photo Name', p2 ? p2.photo_name : 'NA' ]
            elsif type == 'ideas'
              p1 = Photo.find_by_id(row['Idea Text'])
              row << [ 'Photo Name', p1 ? p1.photo_name : 'NA' ]
            end
          end

          case type
            when "votes", "non_votes"

              sid = row['Session Identifier']
              row.delete('Session Identifier')

              user_session = sessions[sid]
              if user_session.nil?
                user_session = SessionInfo.find_by_session_id(sid)
                sessions[sid] = user_session
              end

              unless user_session.nil? #edge case, all appearances and votes after april 8 should have session info
                # Some marketplaces can be accessed via more than one url
                if num_slugs > 1
                  url_alias = url_aliases[sid]

                  if url_alias.nil?
                    max = 0
                    earl.slugs.each do |slug|
                      num = user_session.clicks.count(:conditions => ['url like ?', '%' + slug.name + '%' ])

                      if num > max
                        url_alias = slug.name
                        max = num
                      end
                    end

                    url_aliases[sid] = url_alias
                  end
                else
                  url_alias = earl.name
                end


                row << ['Hashed IP Address', Digest::MD5.hexdigest([user_session.ip_addr, IP_ADDR_HASH_SALT].join(""))]
                row << ['URL Alias', url_alias]
                if current_user.admin?
                  #row << ['Geolocation Info', user_session.loc_info.to_s]
                end
              end
            end
            rows << row.to_csv
        end
        # limit number of updates to MySQL by
        # updating with concat 50000 rows at a time
        if rows.length > 50000
          Export.update_concat(export.id, rows.join(""))
          rows = []
        end
      end
      # update with concat any remaining rows
      Export.update_concat(export.id, rows.join("")) if rows.length > 0
    end

    export.delay(:run_at => 3.days.from_now).destroy
    url = "/export/#{e.name}"
    IdeaMailer.deliver_export_data_ready(email, url, photocracy)

    return true
  end
end
