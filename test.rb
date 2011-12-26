require "date"

class State
  attr_accessor :account_balances
  def initialize(account_balances = {})
    @account_balances = account_balances
  end

  def -(other)
    diff = account_balances
    other.account_balances.each do |acct, bal|
      diff[acct] ||= 0.00
      diff[acct] -= bal
    end

    State.new(diff)
  end
end

class BillingPeriod
  attr_accessor :start_date, :end_date, :due_date
  attr_accessor :min_payment
  def initialize(sd, ed, dd)
    @start_date = sd
    @end_date = ed
    @due_date = dd
  end
end

class Action
  attr_accessor :eff_date, :amount
  def initialize(eff_date, amount)
    @eff_date = eff_date
    @amount = amount
  end

  def draw?; false; end
  def payment?; false; end
end
class Payment < Action
  def payment?; true; end
end
class Draw < Action
  def draw?; true; end
end

class Amortizer
  attr_accessor :billing_periods, :actions
  def initialize(billing_periods, actions)
    @billing_periods = billing_periods
    @actions = actions

    @action_map = actions.reduce({}) do |am, action|
      am[action.eff_date] ||= []
      am[action.eff_date].push(action)

      am
    end
  end

  INTEREST_RATE_YEARLY = 0.28
  INTEREST_RATE_DAILY = INTEREST_RATE_YEARLY / 365.0
  DRAW_FEE_PERCENTAGE = 0.25
   
  ACCOUNTS = ['principal', 'fees', 'interest', 'principal_past_due', 'fees_past_due', 'interest_past_due']

  WATERFALL = ['principal', 'fees', 'interest', 'principal_past_due', 'fees_past_due', 'interest_past_due'].reverse

  MIN_PAYMENT_AMOUNT = 100
  MIN_PAYMENT_PERCENTAGE = 0.15

  def amortize
    # Assumption: billing periods are consecutive and do not skip any days
    
    start_date = billing_periods.first.start_date
    end_date = billing_periods.last.due_date + 1

    principal             = 0.0
    fees                  = 0.0
    interest              = 0.0
    principal_past_due    = 0.0
    fees_past_due         = 0.0
    interest_past_due     = 0.0
    customer_balance      = 0.0

    payments_made         = 0.0
    payments_due          = 0.0

    puts "DATE:\t\tPrin PD\tFees PD\tInt PD\tPrin\t\Fees\tInterest" 

    start_date.upto(end_date) do |date|
      @action_map[date] ||= []

      interest += (principal * INTEREST_RATE_DAILY)

      puts "#{date}: \t" + (WATERFALL.collect { |acct| "%5.2f" % (eval acct) }.join "\t") 

      # Reconcile customer balance.
      if customer_balance > 0.0
          amount = customer_balance
          puts "trying to reconcile customer balance of $#{amount}"
          WATERFALL.each do |account|
            eval("if amount > #{account} then amount -= #{account}; #{account} = 0.0 else #{account} -= amount; amount = 0; end")
            puts "waterfalled over #{account} with #{amount} left"
          end
          customer_balance = amount
      end

      # Handle billing period closes.
      if closed_today = billing_periods.find { |bp| bp.end_date == date - 1 }
        min_payment = [(principal + fees) * MIN_PAYMENT_PERCENTAGE + interest, MIN_PAYMENT_AMOUNT].max
        min_payment = [min_payment, principal + fees + interest].min

        closed_today.min_payment = min_payment
        puts "statement closed today with min payment of #{min_payment}"
      end

      # Handle billing period due-dates.
      if due_today = billing_periods.find { |bp| bp.due_date == date }
        puts "statement due today... checking for payments"
        payments_due += due_today.min_payment

        if payments_made < payments_due
          puts "payment was missed! $#{payments_due - payments_made} is in default"

          default_balance = payments_due - payments_made
          ['interest','fees','principal'].each do |account|
            eval "if #{account} <= default_balance
              #{account}_past_due += #{account}
              default_balance -= #{account}
              #{account} = 0.0
            else
              #{account}_past_due += default_balance
              #{account} -= default_balance
              default_balance = 0
            end"

            puts "defaulted into #{account} with #{default_balance} left"
          end
          
          
        else
          puts "payment was made"
        end
      end

      # Handle payments.
      @action_map[date].each do |action|
        if action.draw?
          puts "draw made for $#{action.amount}"
          principal += action.amount
          fees += action.amount * DRAW_FEE_PERCENTAGE
        elsif action.payment?
          amount = action.amount
          payments_made += amount
          puts "payment made of $#{amount}"
          WATERFALL.each do |account|
            eval("if amount > #{account} then amount -= #{account}; #{account} = 0.0 else #{account} -= amount; amount = 0; end")
            puts "waterfalled over #{account} with #{amount} left"
          end

          customer_balance += amount
        end        
      end
    end

    balances = ACCOUNTS.reduce({}) do |bals, acct|
      bals[acct] = eval acct
      bals
    end

    return State.new(balances)
  end
end

class BookEntry
  attr_accessor :date, :debit, :credit, :amount
  def initialize(date, debit, credit, amount)
    @date = date
    @debit = debit
    @credit = credit
    @amount = amount
  end
end

class Books
  attr_accessor :entries
  def intialize
    @entries = []
  end

  def push(entry)
    @entries.push(entry) 
  end
end

puts "IN TIMELINE 1, THE PAYMENTS BOTH SUCCEEDED."

bps = [
  BillingPeriod.new(Date.today, Date.today + 3, Date.today + 5), 
  BillingPeriod.new(Date.today + 4, Date.today + 7, Date.today + 10)
]

actions = [
  Draw.new(Date.today, 400),
  Payment.new(Date.today+4, 150),
  Payment.new(Date.today+9, 150)
]

state1 = Amortizer.new(bps, actions).amortize

puts "IN TIMELINE 2, THE FIRST PAYMENT RETURNED."

bps = [
  BillingPeriod.new(Date.today, Date.today + 3, Date.today + 5), 
  BillingPeriod.new(Date.today + 4, Date.today + 7, Date.today + 10)
]

actions = [
  Draw.new(Date.today, 400),
  Payment.new(Date.today+9, 150)
]

state2 = Amortizer.new(bps, actions).amortize

puts "RESULT: "
p state1
p state2
puts "DIFFERENCE: "
p state2 - state1
