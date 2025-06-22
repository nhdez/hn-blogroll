# Stub Devise::Mailer to prevent Zeitwerk loading issues
# This satisfies Zeitwerk's expectation but doesn't actually send emails

class Devise::Mailer < ActionMailer::Base
  # Stub methods to prevent errors
  def confirmation_instructions(record, token, opts={})
    # Do nothing - no email sending
  end

  def reset_password_instructions(record, token, opts={})
    # Do nothing - no email sending
  end

  def unlock_instructions(record, token, opts={})
    # Do nothing - no email sending
  end

  def email_changed(record, opts={})
    # Do nothing - no email sending
  end

  def password_change(record, opts={})
    # Do nothing - no email sending
  end
end