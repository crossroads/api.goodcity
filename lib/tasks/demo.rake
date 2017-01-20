namespace :goodcity do

  #Create user accounts (donors, reviewers, supervisors)
  donor_attributes = [
    { mobile: "+85251111111", first_name: "David", last_name: "Dara51" },
    { mobile: "+85251111112", first_name: "Daniel", last_name: "Dell52" },
    { mobile: "+85251111113", first_name: "Dakota", last_name: "Deryn53" },
    { mobile: "+85251111114", first_name: "Delia", last_name: "Devon54" },
    { mobile: "+85251111115", first_name: "Della", last_name: "Della55" },
    { mobile: "+85251111116", first_name: "Dora", last_name: "Dora56" },
    { mobile: "+85251111117", first_name: "Dori", last_name: "Dori57" },
    { mobile: "+85251111118", first_name: "Deby", last_name: "Deby58" },
    { mobile: "+85251111119", first_name: "Duke", last_name: "Duke59" },
    { mobile: "+85251111110", first_name: "Dammian", last_name: "Dammian60" },
  ]
  donor_attributes.each {|attr| FactoryGirl.create(:user, attr) }

  reviewer_attributes = [
    { mobile: "+85261111111", first_name: "Rachel", last_name: "Riley61" },
    { mobile: "+85261111112", first_name: "Robyn", last_name: "Raina62" },
    { mobile: "+85261111113", first_name: "Rafael", last_name: "Ras63" },
    { mobile: "+85261111114", first_name: "Raj", last_name: "Rakim64" },
    { mobile: "+85261111115", first_name: "Rock", last_name: "Rock64" },
    { mobile: "+85261111116", first_name: "Randy", last_name: "Riley61" },
    { mobile: "+85261111117", first_name: "Rob", last_name: "Rob62" },
    { mobile: "+85261111118", first_name: "Ricky", last_name: "Ricky63" },
    { mobile: "+85261111119", first_name: "Rain", last_name: "Rain64" },
    { mobile: "+85261111110", first_name: "Ronda", last_name: "Ronda64" },
  ]
  reviewer_attributes.each {|attr| FactoryGirl.create(:user, :reviewer, attr) }

  supervisor_attributes = [
    { mobile: "+85291111111", first_name: "Sarah", last_name: "Sahn91" },
    { mobile: "+85291111112", first_name: "Sally", last_name: "Salwa92" },
    { mobile: "+85291111113", first_name: "Saad", last_name: "Safa93" },
    { mobile: "+85291111114", first_name: "Scott", last_name: "Sandro94" },
    { mobile: "+85291111115", first_name: "Sandy", last_name: "Paul94" },
    { mobile: "+85291111111", first_name: "Sherril", last_name: "Mahood91" },
    { mobile: "+85291111112", first_name: "Stephen", last_name: "Allis92" },
    { mobile: "+85291111113", first_name: "Scott", last_name: "Kanz93" },
    { mobile: "+85291111114", first_name: "Sabina", last_name: "Shue94" },
    { mobile: "+85291111115", first_name: "Sharda", last_name: "Garr94" },
  ]
  supervisor_attributes.each {|attr| FactoryGirl.create(:user, :supervisor, attr) }

  #Create 10 draft offers, 10 submitted, 10 under_review, 10 reviewed, 10 scheduled (with_transport), 10 closed(with_transport)
  message=["Thank you for this", "What an excellent thing.", "Thanks for your reply", "We thank you for choosing to donate.", "The item is in good condition"]

  10.times do
    offer=FactoryGirl.create(:offer, :with_items, :with_messages)
    offer.update_attributes(messages_attributes: {body: message[Random.rand(message.size)]} )
  end

  10.times do
    offer=FactoryGirl.create(:offer, :submitted, :with_items, :with_messages)
    offer.update_attributes( messages_attributes: {body: message[Random.rand(message.size)]} )
  end

  10.times do
    offer=FactoryGirl.create(:offer, :under_review, :with_items, :with_messages)
    offer.update_attributes( messages_attributes: { body: message[Random.rand(message.size)] })
  end

  10.times do
    offer=FactoryGirl.create(:offer, :reviewed, :with_items, :with_messages)
    offer.update_attributes( messages_attributes: { body: message[Random.rand(message.size)] })
  end

  10.times do
    offer=FactoryGirl.create(:offer, :scheduled, :with_transport, :with_items, :with_messages)
    offer.update_attributes( messages_attributes: { body: message[Random.rand(message.size)] })
  end

  10.times do
    offer=FactoryGirl.create(:offer, :closed, :with_transport, :with_items, :with_messages)
    offer.update_attributes( messages_attributes: { body: message[Random.rand(message.size)] })
  end



end
