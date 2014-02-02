require 'spec_helper'

describe Event do
  before (:each)  do
    somebody = FactoryGirl.create(:user)
    r = FactoryGirl.create(:role, name: 'Editor')
    somebody.roles << r
    visit new_user_session_path
    fill_in 'user_email', :with => somebody.email
    fill_in 'user_password', :with => somebody.password
    click_on 'Sign in'
  end

  describe 'forms' do
    let(:event)   { FactoryGirl.create(:event)}
    let(:person1) { FactoryGirl.create(:person)}
    let(:person2) { FactoryGirl.create(:person)}
    let(:person3) { FactoryGirl.create(:person)}
    let(:person4) { FactoryGirl.create(:person)}
    let(:person5) { FactoryGirl.create(:person)}

    it "creates" do
      visit new_event_path
      fill_in "Title", with: "Standard Patrol"
      select 'Patrol', :from => 'event_category'
      select('Completed', :from => 'event_status')
      fill_in "Description", with: "Really Long Text..."
      fill_in "Start Time", with: "2013-10-31 18:30"
      fill_in "End Time", with: "2013-10-31 23:55"
      click_on 'Create'
      page.should have_content "Event was successfully created."
    end

    it "has the right timecards" do
      event.timecards.count.should eq(0)
      person2.should_not be_nil
      @timecard_person1 = FactoryGirl.create(:timecard, event: event, person: person1, intention: "Unknown")
      @timecard_person2 = FactoryGirl.create(:timecard, event: event, person: person2, intention: "Unavailable")
      @timecard_person3 = FactoryGirl.create(:timecard, event: event, person: person3, intention: "Available")
      @timecard_person4 = FactoryGirl.create(:timecard, event: event, person: person4, intention: "Scheduled")
      @timecard_person5 = FactoryGirl.create(:timecard, event: event, person: person5, intention: "Scheduled", 
                                             outcome: "Worked", actual_start_time: "2013-10-31 18:30", actual_end_time: "2013-10-31 19:30" )
      event.timecards.count.should eq(5)
      event.roster('Available').count.should eq(1)
      event.roster('Available').first.should eq(person3)
      @timecard_person2.should_not be_nil
      @timecard_person2.intention.should eq('Unavailable')
      @timecard_person2.event.should eq(event)
      @timecard_person2.person.should eq(person2)
      event.roster('unavailable').count.should eq(1)
      event.roster('unavailable').first.should eq(person2)
      event.roster('Scheduled').count.should eq(1)
      event.roster('Scheduled').first.should eq(person4)
      event.roster('Unknown').count.should eq(1)
      event.roster('Unknown').first.should eq(person1)
      visit event_path(event)  #Need to reload it after the changes to the timecards
      current_path.should == event_path(event)
      within("#event_timecards") do

        within("#unknown") do
          page.should have_content(person1.fullname)
          page.should_not have_content(person2.fullname)
          page.should_not have_content(person3.fullname)
          page.should_not have_content(person4.fullname)
          page.should_not have_content(person5.fullname)
        end

        within("#unavailable") do
          page.should have_content(person2.fullname)
          page.should_not have_content(person1.fullname)
          page.should_not have_content(person3.fullname)
          page.should_not have_content(person4.fullname)
          page.should_not have_content(person5.fullname)
         end

        within("#available") do
          page.should have_content(person3.fullname)
          page.should_not have_content(person1.fullname)
          page.should_not have_content(person2.fullname)
          page.should_not have_content(person4.fullname)
          page.should_not have_content(person5.fullname)
        end

        within("#scheduled") do
          page.should have_content(person4.fullname)
          page.should_not have_content(person1.fullname)
          page.should_not have_content(person2.fullname)
          page.should_not have_content(person3.fullname)
          page.should_not have_content(person5.fullname)
         end

        within("#worked") do
          page.should have_content(person5.fullname)
          page.should_not have_content(person1.fullname)
          page.should_not have_content(person2.fullname)
          page.should_not have_content(person3.fullname)
          page.should_not have_content(person4.fullname)
        end
      end
    end
  end
  describe "displays" do
    let!(:event) {FactoryGirl.create(:event) }
    let(:notification) {FactoryGirl.create(:notification, event: event)}

    it "a listing" do
      @event = FactoryGirl.create(:event, end_time: nil, title: "Something divine")
      visit events_path

      within_table("events") do
        page.should have_content("Events")
      	within("tbody") do
      	  page.should have_content(@event.description)
      	end
      end
    end

    it 'an edit form' do
      @event = FactoryGirl.create(:event, end_time: nil, title: "Something divine")
      visit edit_event_path(@event)
      within("#sidebar") do
        page.should have_content("Cancel")
      end
    end

    it "an event page" do
      visit event_path(event)
      within('#submenu') do
        page.should have_content "Edit"
      end
      page.should have_content(event.title)
      current_path.should == event_path(event)
    end
    it 'shows notifications on the event page' do
      notification.event.should eq(event) # Needed to fire lazy loading
      visit event_path(event)
      within("#event_notifications") do
        page.should have_content(notification.subject)
        click_on notification.subject
        current_path.should == notification_path(notification)
      end
    end
    it "hides the course if category isn't training" , js: true do
      visit new_event_path
      select 'Patrol', :from => 'event_category'
      fill_in "Description", with: "Really Long Text..."  #This ensures the blur event happens
      page.should_not have_content("Course")
      select 'Training', :from => 'event_category'
      fill_in "Description", with: "Really Long Text..."  #This ensures the blur event happens
      page.should have_content("Course")
    end
    it "always fails" do
     #1.should eq(2)
    end
  end
end
