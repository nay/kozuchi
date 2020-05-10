shared_context 'when no deals and patterns exist', :no_deals_and_patterns do
  before do
    Deal::Base.destroy_all
    Entry::Base.destroy_all
    Pattern::Deal.destroy_all
    Pattern::Entry.destroy_all
  end
end
