# frozen_string_literal

namespace :goodcity do
  namespace :canned_messages do
    desc 'Initialize CannedResponse'
    task initialize_canned_response: :environment do
      CannedResponse.delete_all
      count = 0
      canned_responses = YAML.load_file("#{Rails.root}/db/canned_responses.yml")
      canned_responses.each_value do |_k, v|
        canned_response = CannedResponse.new(v)
        if canned_response.save
          count += 1
        else
          puts "Error while creating #{v} \n Error: #{canned_response.errors.full_messages}"
        end
      end
      puts "Succesfully created #{count} records"
    end

    desc 'Add / Update System Messages in CannedResponse'
    task update_canned_system_messages: :environment do
      canned_response = [{  guid: 'logistics-complete-review-message',
                            name_en: 'Logistics - Complete Review Message',
                            content_en: 'Your offer has been reviewed. Please [click_here|transport_page] to arrange transportation.',
                            content_zh_tw: '已完成審查閣下的捐獻項目， 請 [click_here|transport_page] 安排遞送服務。',
                            message_type: CannedResponse::Type::SYSTEM
                          }, {
                            guid: 'review-offer-close-offer-message',
                            name_en: 'Review offer - Close offer message',
                            content_en: 'We have finished processing your offer. Unfortunately we are unable to receive your items this time. We hope we can place items you offer in the future.',
                            content_zh_tw: '閣下的捐贈項目處理完畢，但我們現時無法接收閣下的物資，請見諒，還望下次有機會為閣下的物資找到合適的安置。',
                            message_type: CannedResponse::Type::SYSTEM
                          }, {
                            guid: 'review-offer-missing-offer-message',
                            name_en: 'Review offer - Missing offer message',
                            content_en: 'The delivery arrived at Crossroads but expected items were missing. We may follow up with you to confirm what happened.',
                            content_zh_tw: '貨車已抵達十字路會，惟未見物資，我們或會和你跟進，確認事件狀況。',
                            message_type: CannedResponse::Type::SYSTEM
                          }, {
                            guid: 'review-offer-receive-offer-message',
                            name_en: 'Review offer - Receive offer message',
                            content_en: 'Your offer was received, thank you.',
                            content_zh_tw: '已經收到你捐贈的物資，謝謝。',
                            message_type: CannedResponse::Type::SYSTEM
                          }]
      canned_response.each do |attr|
        record = CannedResponse.find_or_initialize_by(guid: attr[:guid])
        record.assign_attributes(attr)
        record.save!
      end
    end

    desc 'Remove all System Messages from CannedResponse'
    task delete_canned_system_messages: :environment do
      CannedResponse.by_private(true).delete_all
    end
  end
end
