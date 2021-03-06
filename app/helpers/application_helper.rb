module ApplicationHelper
##############################################################################################
######################################### Curl calls #########################################
##############################################################################################


  def server_user
    return "dogecoinrpc"
    #return "USER"
  end

  def server_pass
    file = File.open("/home/key/deamon.key", "rb")
    return file.read.chomp
  end

  def server_passphrase
    file = File.open("/home/key/phrase.key", "rb")
    return file.read.chomp
  end

  #create account name and return account address
  def curlCreateNewAccount name
    system 'curl --user '+server_user+':'+server_pass+' --data-binary \'{"jsonrpc": "1.0", "id":"chuy", "method": "getnewaddress", "params": ["'+name+'"] }\' -H \'content-type: text/plain;\' http://localhost:22555 > '+Rails.root.to_s+'/public/'+name+'.html'

    file = File.open("public/"+name+".html", "rb")
    contents = file.read

    require 'json'
    hash = JSON.parse contents

    return hash["result"]
  end

  #send to address
  def curlSendToAddress address, prize

    system 'curl -u '+server_user+':'+server_pass+' --data-binary \'{"jsonrpc": "1.0", "id":"chuy", "method": "walletpassphrase", "params": ["'+server_passphrase+'",999] }\' -H \'content-type: text/plain;\' http://localhost:22555'

    system 'curl -u '+server_user+':'+server_pass+' --data-binary \'{"jsonrpc": "1.0", "id":"chuy", "method": "sendtoaddress", "params": ["'+address+'",'+prize.to_s+'] }\' -H \'content-type: text/plain;\' http://localhost:22555'

  end

  def curlGetDeposits name
    system 'curl --user '+server_user+':'+server_pass+' --data-binary \'{"jsonrpc": "1.0", "id":"chuy", "method": "listtransactions", "params": ["'+name+'",100,0] }\' -H \'content-type: text/plain;\' http://localhost:22555 > '+Rails.root.to_s+'/public/'+name+'.html'

    file = File.open("public/"+name+".html", "rb")
    contents = file.read

    require 'json'
    hash = JSON.parse contents

    output=hash["result"][0]

    deposits=0.0
    i=0
    while i<output=hash["result"].size
      if output=hash["result"][i]["category"]=="receive"
        hash["result"][i]
        deposits+=hash["result"][i]["amount"].to_d
      end
      i+=1
    end
    return deposits
	end

  def curlGetConfirmedDeposits name
    system 'curl --user '+server_user+':'+server_pass+' --data-binary \'{"jsonrpc": "1.0", "id":"chuy", "method": "listtransactions", "params": ["'+name+'",100,0] }\' -H \'content-type: text/plain;\' http://localhost:22555 > '+Rails.root.to_s+'/public/'+name+'.html'

    file = File.open("public/"+name+".html", "rb")
    contents = file.read

    require 'json'
    hash = JSON.parse contents

    output=hash["result"][0]

    deposits=0.0
    i=0
    while i<output=hash["result"].size
      if output=hash["result"][i]["category"]=="receive" && output=hash["result"][i]["confirmations"] >= 3
        hash["result"][i]
        deposits+=hash["result"][i]["amount"].to_d
      end
      i+=1
    end
    return deposits
  end

#############################################################################
##################################### User transactions #####################
#############################################################################

  def getDeposits user
    return curlGetDeposits user.name
  end

  def getConfirmedDeposits user
    return curlGetConfirmedDeposits user.name
  end

  def getCreditsPlayed user
    credits = 0
    user.chests.each do |c|
      credits+=c.price
    end
    return credits
  end

  def getWithdraws user
    credits = 0
    user.withdraws.each do |w|
      credits+=w.amount
    end
    return credits
  end

  def getCreditsWon user
    credits = 0
    user.chests.each do |c|
      if c.multiplier == nil
        credits+=c.prize
      else
        credits+=c.prize*c.multiplier
      end
    end
    return credits
  end

  def getAvailableCredits user
    return (curlGetConfirmedDeposits user.name) + (getCreditsWon user) - (getCreditsPlayed user) - (getWithdraws user)
  end
end
