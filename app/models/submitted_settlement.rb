# -*- encoding : utf-8 -*-
class SubmittedSettlement < Settlement
  # destroy時に自動でnilにしてもらうため
  has_one :resource, :class_name => 'Settlement', :foreign_key => 'submitted_settlement_id', :dependent => :nullify
  
  # submitはできない
  def submit
    raise "相手から提出済にされることによってできた精算データを提出することはできません。"
  end
  
  protected
  def validate
    
  end

  private

  def create_result_deal
  end

end