require 'thread'

class ChatsController < ApplicationController
  # GET /chatPartner
  def show
    Thread.current[:nearID] = params[:farID]

    # find ourselves a chat partner
    # TODO: prevent anyone else from finding the same partner
    threads = Thread.list.select { |t| t.key?(:matching) }
    luckyThread = threads.sample()
    if luckyThread
      # great, we found one
      farID = luckyThread[:nearID]
      luckyThread[:farID] = Thread.current[:nearID]
      luckyThread.wakeup()
    else
      # no such luck, hopefully someone will come for us
      Thread.current[:matching] = "" # raise the "come find me" flag
      sleep(10)
      farID = Thread.current[:farID]
    end

    if farID
      render :xml => farID
    else
      render :xml => ""
    end
  end
end
