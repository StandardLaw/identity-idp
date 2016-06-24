module Idv
  class ConfirmationsController < ApplicationController
    include IdvSession

    before_action :confirm_two_factor_authenticated

    def index
      if proofing_session_started?
        if idv_question_number >= idv_resolution.questions.count
          submit_answers
        else
          redirect_to idv_questions_url
        end
      else
        redirect_to idv_sessions_url
      end
    end

    private

    def submit_answers
      agent = Proofer::Agent.new(vendor: idv_vendor, applicant: idv_applicant)
      @idv_vendor = idv_vendor
      @confirmation = agent.submit_answers(idv_resolution.questions, idv_resolution.session_id)
      # HANDWAVING actually alter the user
      clear_idv_session
    end
  end
end
