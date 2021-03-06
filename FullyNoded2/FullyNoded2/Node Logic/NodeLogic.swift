//
//  NodeLogic.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class NodeLogic {
    
    let dateFormatter = DateFormatter()
    var errorBool = Bool()
    var errorDescription = ""
    var dictToReturn = [String:Any]()
    var arrayToReturn = [[String:Any]]()
    var walletDisabled = Bool()
    var wallet:WalletStruct!
    
    func loadTorData(completion: @escaping () -> Void) {
        
        let reducer = Reducer()
        reducer.makeCommand(walletName: "", command: .getnetworkinfo, param: "") {
            
            if !reducer.errorBool {
                
                if reducer.dictToReturn != nil {
                    
                    let networkInfo = reducer.dictToReturn!
                    
                    if let subversionCheck = networkInfo["subversion"] as? String {
                        
                        let subversion = subversionCheck.replacingOccurrences(of: "/", with: "")
                        self.dictToReturn["subversion"] = subversion.replacingOccurrences(of: "Satoshi:", with: "")
                        
                        if let localaddresses = networkInfo["localaddresses"] as? NSArray {
                            
                            if localaddresses.count > 0 {
                                
                                for address in localaddresses {
                                    
                                    if let dict = address as? NSDictionary {
                                        
                                        if let p2pAddress = dict["address"] as? String {
                                            
                                            if let port = dict["port"] as? Int {
                                                
                                                if p2pAddress.contains("onion") {
                                                    
                                                    self.dictToReturn["p2pOnionAddress"] = p2pAddress + ":" + "\(port)"
                                                    
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let networks = networkInfo["networks"] as? NSArray {
                            
                            for network in networks {
                                
                                if let dict = network as? NSDictionary {
                                    
                                    if let name = dict["name"] as? String {
                                        
                                        if name == "onion" {
                                            
                                            if let reachable = dict["reachable"] as? Bool {
                                                
                                                self.dictToReturn["reachable"] = reachable
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                        completion()
                        
                    }
                    
                } else {
                    
                    self.errorBool = true
                    self.errorDescription = "returned object is nil"
                    completion()
                    
                }
                
            } else {
                
                self.errorBool = true
                self.errorDescription = "\(reducer.errorDescription)"
                completion()
                
            }
            
        }
        
    }
    
    func loadWalletData(completion: @escaping () -> Void) {
        print("loadWalletData")
        
        let reducer = Reducer()
        
        func getResult() {
            
            if !reducer.errorBool {
                
                switch reducer.method {
                    
                case BTC_CLI_COMMAND.listunspent.rawValue:
                    
                    if reducer.arrayToReturn != nil {
                        
                        let utxos = reducer.arrayToReturn!
                        parseUtxos(utxos: utxos)
                        completion()
                        
                    } else {
                        
                        self.errorBool = true
                        self.errorDescription = "returned object is nil"
                        completion()
                        
                    }
                                        
                default:
                    
                    print("break1")
                    break
                    
                }
                
            } else {
                
                errorBool = true
                errorDescription = reducer.errorDescription
                print("errorDescription = \(errorDescription)")
                
                if errorDescription.contains("Requested wallet does not exist or is not loaded") {
                    
                    // possibly changed from mainnet to testnet or vice versa, try and load once
                    reducer.errorDescription = ""
                    reducer.errorBool = false
                    errorDescription = ""
                    errorBool = false
                    
                    reducer.makeCommand(walletName: wallet.name, command: .loadwallet, param: "\"\(wallet.name)\"") {
                        
                        if !reducer.errorBool {
                            
                            reducer.makeCommand(walletName: self.wallet.name, command: .listunspent,
                                                param: "0",
                                                completion: getResult)
                            
                        } else {
                            
                            self.errorBool = true
                            self.errorDescription = "Wallet does not exist, maybe you changed networks? If you want to use the app on a different network you will need to recreate the wallet"
                            completion()
                            
                        }
                        
                    }
                    
                } else {
                    
                     completion()
                    
                }
                
            }
            
        }
        
        if !walletDisabled {
            
            reducer.makeCommand(walletName: wallet.name, command: .listunspent,
                                param: "0",
                                completion: getResult)
            
        } else {
            
            dictToReturn["coldBalance"] = "disabled"
            dictToReturn["unconfirmedBalance"] = "disabled"
            completion()
            
        }
        
    }
    
    func loadNodeData(completion: @escaping () -> Void) {
        print("loadNodeData")
        
        let reducer = Reducer()
        
//        var walletName = ""
//        
//        if wallet != nil {
//            
//            walletName = wallet!.name
//            
//        }
        
        func getResult() {
            
            if !reducer.errorBool {
                
                switch reducer.method {
                    
                case BTC_CLI_COMMAND.estimatesmartfee.rawValue:
                    
                    if reducer.dictToReturn != nil {
                        
                        let result = reducer.dictToReturn!
                        
                        if let feeRate = result["feerate"] as? Double {
                            
                            let btcperbyte = feeRate / 1000
                            let satsperbyte = (btcperbyte * 100000000).avoidNotation
                            dictToReturn["feeRate"] = "\(satsperbyte) s/b"
                            
                        } else {
                            
                            if let errors = result["errors"] as? NSArray {
                                
                                dictToReturn["feeRate"] = "\(errors[0] as! String)"
                                
                            }
                           
                        }
                        
                        completion()
                        
                    } else {
                        
                        self.errorBool = true
                        self.errorDescription = "returned object is nil"
                        completion()
                        
                    }
                    
                case BTC_CLI_COMMAND.getmempoolinfo.rawValue:
                    
                    if reducer.dictToReturn != nil {
                        
                        let dict = reducer.dictToReturn!
                        
                        if let mempoolSize = dict["size"] as? Int {
                            
                            dictToReturn["mempoolCount"] = mempoolSize
                            
                        } else {
                            
                            dictToReturn["mempoolCount"] = 0
                            
                        }
                        
                        let feeRate = UserDefaults.standard.integer(forKey: "feeTarget")
                        
                        reducer.makeCommand(walletName: "", command: .estimatesmartfee,
                                            param: "\(feeRate)",
                                            completion: getResult)
                                                
                    } else {
                        
                        self.errorBool = true
                        self.errorDescription = "returned object is nil"
                        completion()
                        
                    }
                    
                case BTC_CLI_COMMAND.uptime.rawValue:
                    
                    if reducer.doubleToReturn != nil {
                        
                        dictToReturn["uptime"] = Int(reducer.doubleToReturn!)
                        
                        reducer.makeCommand(walletName: "", command: .getmempoolinfo,
                                            param: "",
                                            completion: getResult)
                                                
                    } else {
                        
                        self.errorBool = true
                        self.errorDescription = "returned object is nil"
                        completion()
                        
                    }
                    
                case BTC_CLI_COMMAND.getmininginfo.rawValue:
                    
                    if reducer.dictToReturn != nil {
                        
                        let miningInfo = reducer.dictToReturn!
                        parseMiningInfo(miningInfo: miningInfo)
                        
                        reducer.makeCommand(walletName: "", command: .uptime,
                                            param: "",
                                            completion: getResult)
                        
                    } else {
                        
                        self.errorBool = true
                        self.errorDescription = "returned object is nil"
                        completion()
                        
                    }
                    
                case BTC_CLI_COMMAND.getpeerinfo.rawValue:
                    
                    if reducer.arrayToReturn != nil {
                        
                        let peerInfo = reducer.arrayToReturn!
                        parsePeerInfo(peerInfo: peerInfo)
                        
                        reducer.makeCommand(walletName: "", command: .getmininginfo,
                                            param: "",
                                            completion: getResult)
                        
                    } else {
                        
                        self.errorBool = true
                        self.errorDescription = "returned object is nil"
                        completion()
                        
                    }
                    
                case BTC_CLI_COMMAND.getblockchaininfo.rawValue:
                    
                    if reducer.dictToReturn != nil {
                        
                        let blockchainInfo = reducer.dictToReturn!
                        parseBlockchainInfo(blockchainInfo: blockchainInfo)
                        
                        reducer.makeCommand(walletName: "", command: .getpeerinfo,
                                            param: "",
                                            completion: getResult)
                        
                    } else {
                        
                        self.errorBool = true
                        self.errorDescription = "returned object is nil"
                        completion()
                        
                    }
                    
                default:
                    
                    break
                    
                }
                
            } else {
                
                errorBool = true
                errorDescription = reducer.errorDescription
                completion()
                
            }
            
        }
        
        reducer.makeCommand(walletName: "", command: .getblockchaininfo,
                            param: "",
                            completion: getResult)
        
    }
    
    func loadTransactionData(completion: @escaping () -> Void) {
        print("loadTransactionData")
        
        let reducer = Reducer()
        
        func getResult() {
            
            if !reducer.errorBool {
                
                switch reducer.method {
                    
                case BTC_CLI_COMMAND.listtransactions.rawValue:
                    
                    if reducer.arrayToReturn != nil {
                        
                        let transactions = reducer.arrayToReturn!
                        parseTransactions(transactions: transactions)
                        completion()
                        
                    } else {
                        
                        self.errorBool = true
                        self.errorDescription = "returned object is nil"
                        completion()
                        
                    }
                                        
                default:
                    
                    break
                    
                }
                
            } else {
                
                errorBool = true
                errorDescription = reducer.errorDescription
                completion()
                
            }
            
        }
        
        if !walletDisabled {
            
            reducer.makeCommand(walletName: wallet.name, command: .listtransactions,
                                param: "\"*\", 50, 0, true",
                                completion: getResult)
            
        } else {
            
            arrayToReturn = []
            completion()
            
        }
        
    }
    
    // MARK: Parsers
    
    func parseUtxos(utxos: NSArray) {
        
        var amount = 0.0
        
        if utxos.count == 0 {
            
            dictToReturn["noUtxos"] = true
            
        } else {
            
            dictToReturn["noUtxos"] = false
            
        }
        
        for utxo in utxos {
            
            print("utxo = \(utxo)")
            
            if let utxoDict = utxo as? NSDictionary {
                
                // Here we check the utxos descriptor to see what the path is for each pubkey.
                // We take the highest index for each pubkey and compare it to the wallets index.
                // If the wallets index is less than or equal to the highest utxo index we increase
                // the wallets index to be greater then the highest utxo index. This way we avoid
                // reusing an address in the scenario where a user may use external software to
                // receive to the app or for example they export their keys within the app and use
                // random addresses as invoices.
                
                if let desc = utxoDict["desc"] as? String {
                    
                    print("desc = \(desc)")
                    let p = DescriptorParser()
                    let str = p.descriptor(desc)
                    let paths = str.derivationArray
                    print("paths = \(paths)")
                    var index = 0
                    for path in paths {
                        
                        let arr = path.split(separator: "/")
                        
                        for (i, comp) in arr.enumerated() {
                            
                            if i + 1 == arr.count {
                                
                                if let int = Int(comp) {
                                    
                                    if int > index {
                                        
                                        index = int
                                        
                                    }
                                    
                                }
                                                                
                            }
                            
                        }
                        
                    }
                    
                    print("index = \(index)")
                    if wallet.index <= index {
                        
                        let cd = CoreDataService()
                        cd.updateEntity(id: wallet.id, keyToUpdate: "index", newValue: index, entityName: .wallets) {
                            
                            if !cd.errorBool {
                                
                                print("updated index from utxo")
                                
                            } else {
                                
                                print("failed to update index from utxo")
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
                if let spendable = utxoDict["spendable"] as? Bool {
                    
                    if let confirmations = utxoDict["confirmations"] as? Int {
                        
                        if !spendable {
                            
                            if let balance = utxoDict["amount"] as? Double {
                                
                                amount += balance
                                
                            }
                            
                        }
                        
                        if confirmations < 1 {
                            
                            dictToReturn["unconfirmed"] = true
                            
                        } else {
                            
                            dictToReturn["unconfirmed"] = false
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        if amount == 0.0 {
            
            dictToReturn["coldBalance"] = "0.0"
            
        } else {
            
            dictToReturn["coldBalance"] = "\((round(100000000*amount)/100000000).avoidNotation)"
            
        }
        
    }
    
    // MARK: Section 1 parsers
    
    func parseMiningInfo(miningInfo: NSDictionary) {
        
        if let hashesPerSecond = miningInfo["networkhashps"] as? Double {
         
            let exahashesPerSecond = hashesPerSecond / 1000000000000000000
            dictToReturn["networkhashps"] = Int(exahashesPerSecond).withCommas()
            
        }
        
    }
    
    func parseBlockchainInfo(blockchainInfo: NSDictionary) {
        
        if let currentblockheight = blockchainInfo["blocks"] as? Int {
            
            dictToReturn["blocks"] = currentblockheight
            let ud = UserDefaults.standard
            ud.set(currentblockheight, forKey: "blockheight")
            
        }
        
        if let difficultyCheck = blockchainInfo["difficulty"] as? Double {
            
            dictToReturn["difficulty"] = "\(Int(difficultyCheck / 1000000000000).withCommas()) trillion"
            
        }
        
        if let sizeCheck = blockchainInfo["size_on_disk"] as? Int {
            
            dictToReturn["size"] = "\(sizeCheck/1000000000) gb"
            
        }
        
        if let progressCheck = blockchainInfo["verificationprogress"] as? Double {
            
            dictToReturn["progress"] = "\(Int(progressCheck*100))%"
            
        }
        
        if let chain = blockchainInfo["chain"] as? String {
            
            dictToReturn["chain"] = chain
            
        }
        
        if let pruned = blockchainInfo["pruned"] as? Bool {
            
            dictToReturn["pruned"] = pruned
            
        }
        
    }
    
    func parsePeerInfo(peerInfo: NSArray) {
        
        var incomingCount = 0
        var outgoingCount = 0
        
        for peer in peerInfo {
            
            if let peerDict = peer as? NSDictionary {
                
                if let incoming = peerDict["inbound"] as? Bool {
                    
                    if incoming {
                        
                        incomingCount += 1
                        dictToReturn["incomingCount"] = incomingCount
                        
                    } else {
                        
                        outgoingCount += 1
                        dictToReturn["outgoingCount"] = outgoingCount
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func parseTransactions(transactions: NSArray) {
        
        var transactionArray = [[String:Any]]()
        
        for item in transactions {
            
            if let transaction = item as? NSDictionary {
                
                var label = String()
                var replaced_by_txid = String()
                var isCold = false
                
                let address = transaction["address"] as? String ?? ""
                let amount = transaction["amount"] as? Double ?? 0.0
                
                if amount.avoidNotation != "" {
                    
                    let amountString = amount.avoidNotation
                    let confsCheck = transaction["confirmations"] as? Int ?? 0
                    let confirmations = "\(confsCheck)"
                    
                    if let replaced_by_txid_check = transaction["replaced_by_txid"] as? String {
                        
                        replaced_by_txid = replaced_by_txid_check
                        
                    }
                    
                    if let labelCheck = transaction["label"] as? String {
                        
                        label = labelCheck
                        
                        if labelCheck == "" {
                            
                            label = ""
                            
                        }
                        
                        if labelCheck == "," {
                            
                            label = ""
                            
                        }
                        
                    } else {
                        
                        label = ""
                        
                    }
                    
                    let secondsSince = transaction["time"] as? Double ?? 0.0
                    let rbf = transaction["bip125-replaceable"] as? String ?? ""
                    let txID = transaction["txid"] as? String ?? ""
                    
                    let date = Date(timeIntervalSince1970: secondsSince)
                    dateFormatter.dateFormat = "MMM-dd-yyyy HH:mm"
                    let dateString = dateFormatter.string(from: date)
                    
                    if let boolCheck = transaction["involvesWatchonly"] as? Bool {
                        
                        isCold = boolCheck
                        
                    }
                    
                    transactionArray.append(["address": address,
                                             "amount": amountString,
                                             "confirmations": confirmations,
                                             "label": label,
                                             "date": dateString,
                                             "rbf": rbf,
                                             "txID": txID,
                                             "replacedBy": replaced_by_txid,
                                             "involvesWatchonly":isCold,
                                             "selfTransfer":false,
                                             "remove":false])
                    
                }
                
            }
            
        }
        
        for (i, tx) in transactionArray.enumerated() {
            
            if let _ = tx["amount"] as? String {
                
                if let amount = Double(tx["amount"] as! String) {
                    
                    if let txID = tx["txID"] as? String {
                        
                        for (x, transaction) in transactionArray.enumerated() {
                            
                            if let amountToCompare = Double(transaction["amount"] as! String) {
                                
                                if x != i && txID == (transaction["txID"] as! String) {
                                    
                                    if amount + amountToCompare == 0 && amount > 0 {
                                        
                                        transactionArray[i]["selfTransfer"] = true
                                        
                                    } else if amount + amountToCompare == 0 && amount < 0 {
                                        
                                        transactionArray[i]["remove"] = true
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
                            
        for tx in transactionArray {
            
            if let remove = tx["remove"] as? Bool {
                
                if !remove {
                    
                    arrayToReturn.append(tx)
                    
                }
                
            }
            
        }
        
    }
    
}
