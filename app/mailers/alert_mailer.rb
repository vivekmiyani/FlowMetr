class AlertMailer < ApplicationMailer
    def error_triggered_alert(emails, run, point)
      @run = run
      @point = point
      mail(to: emails, subject: "🚨 FlowMetr Alert: Error triggered in #{@point.flow.name}")
    end
  end
  