# Every request "moving" an asset from somewhere to somewhere else without really transforming it
# (chemically) as, cherrypicking, pooling, spreading on the floor etc
class TransferRequest < Request
  TRANSITIONS = {
    'started' => {
      'passed' => :pass!,
      'cancelled' => :cancel!,
      'failed' => :fail!
    },
    'pending' =>{
      'started' => :start!,
      'passed' => :pass!,
      'failed' => :fail!,
      'pending' => :detach!,
      'cancelled' => :cancel_before_started!
    },
    'passed' => {
      'failed' => :fail!
    },
    'cancelled' => {
    },
    'failed' => {
      'passed' => :pass!
    },
    'hold' => {
    },
    'blocked' => {
    }
  }

  redefine_state_machine do
    # The statemachine for transfer requests is more promiscuous than normal requests, as well
    # as being more concise as it has less states.
    aasm_column :state
    aasm_state :pending
    aasm_state :started
    aasm_state :failed
    aasm_state :passed
    aasm_state :cancelled
    aasm_initial_state :pending

    # State Machine events
    aasm_event :start do
      transitions :to => :started, :from => [:pending]
    end

    aasm_event :pass do
      transitions :to => :passed, :from => [:pending, :started, :failed]
    end

    aasm_event :fail do
      transitions :to => :failed, :from => [:pending, :started, :passed]
    end

    aasm_event :cancel do
      transitions :to => :cancelled, :from => [:started, :passed]
    end

    aasm_event :cancel_before_started do
      transitions :to => :cancelled, :from => [:pending]
    end

    aasm_event :detach do
      transitions :to => :pending, :from => [:pending]
    end
  end

  def transition_method_to(target_state)
    TransferRequest::TRANSITIONS[state][target_state]
  end
  private :transition_method_to

  # Ensure that the source and the target assets are not the same, otherwise bad things will happen!
  validate do |record|
    if record.asset.present? and record.asset == record.target_asset
      record.errors.add(:asset, 'cannot be the same as the target')
      record.errors.add(:target_asset, 'cannot be the same as the source')
    end
  end

  before_create(:add_request_type)
  def add_request_type
    self.request_type ||= RequestType.transfer
  end
  private :add_request_type

  after_create(:perform_transfer_of_contents)

  def perform_transfer_of_contents
    target_asset.aliquots << asset.aliquots.map(&:clone) unless asset.failed? or asset.cancelled?
  end
  private :perform_transfer_of_contents
end
