//
//  KeyFetcher.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation
import LibWally

class KeyFetcher {
    
    let enc = Encryption()
    
    func fingerprint(wallet: WalletStruct, completion: @escaping ((fingerprint: String?, error: Bool)) -> Void) {
        
        let derivationPath = wallet.derivation
        
        if String(data: wallet.seed, encoding: .utf8) != "no seed" {
            
            self.enc.decryptData(dataToDecrypt: wallet.seed) { (seed) in
                
                if seed != nil {
                    
                    if let words = String(data: seed!, encoding: .utf8) {
                                            
                        let mnenomicCreator = MnemonicCreator()
                        mnenomicCreator.convert(words: words) { (mnemonic, error) in
                            
                            if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivationPath)) {
                                
                                completion((masterKey.fingerprint.hexString, false))
                                
                            } else {
                                
                                print("error getting master key")
                                completion((nil, true))
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        } else {
            
            completion((nil, true))
            print("no seed")
            
        }
        
    }
    
    func privKey(path: BIP32Path, completion: @escaping ((privKey: String?, error: Bool)) -> Void) {
        
        getActiveWalletNow() { (wallet, error) in
            
            if wallet != nil && !error {
                
                let derivationPath = wallet!.derivation
                
                if String(data: wallet!.seed, encoding: .utf8) != "no seed" {
                    
                    self.enc.decryptData(dataToDecrypt: wallet!.seed) { (seed) in
                        
                        if seed != nil {
                            
                            let words = String(data: seed!, encoding: .utf8)!
                            
                            let mnenomicCreator = MnemonicCreator()
                            
                            mnenomicCreator.convert(words: words) { (mnemonic, error) in
                                
                                if !error {
                                    
                                    if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivationPath)) {
                                        
                                        do {
                                            
                                            let key = try masterKey.derive(path)
                                            
                                            if let keyToReturn = key.privKey {
                                                
                                                let wif = keyToReturn.wif
                                                completion((wif,false))
                                                
                                            } else {
                                                
                                                completion((nil,true))
                                                
                                            }
                                            
                                        } catch {
                                            
                                            completion((nil,true))
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((nil,true))
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((nil,true))
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    if wallet!.xprv != nil {
                        
                        // its a recovered wallet without a mnemonic, need to remove the account derivation as we know the psbt will return the full path
                        var processedDerivation = ""
                        let arr = "\(path)".split(separator: "/")
                        for (i, pathComponent) in arr.enumerated() {
                            
                            if i > 3 {
                                
                                processedDerivation += "/" + "\(pathComponent)"
                                
                            }
                            
                            if i + 1 == arr.count {
                                
                                if let accountLessPath = BIP32Path(processedDerivation) {
                                    
                                    self.enc.decryptData(dataToDecrypt: wallet!.xprv!) { (decryptedXprv) in
                                        
                                        if decryptedXprv != nil {
                                            
                                            if let xprvString = String(data: decryptedXprv!, encoding: .utf8) {
                                                
                                                if let hdKey = HDKey(xprvString) {
                                                    
                                                    do {
                                                        
                                                        let key = try hdKey.derive(accountLessPath)
                                                        
                                                        if let keyToReturn = key.privKey {
                                                            
                                                            let wif = keyToReturn.wif
                                                            completion((wif,false))
                                                            
                                                        } else {
                                                            
                                                            completion((nil,true))
                                                            
                                                        }
                                                        
                                                    } catch {
                                                        
                                                        completion((nil,true))
                                                        print("failed deriving child key")
                                                        
                                                    }
                                                    
                                                }
                                                
                                            }
                                            
                                        } else {
                                            
                                            completion((nil,true))
                                            print("failed decrypting xprv")
                                            
                                        }
                                        
                                    }
                                    
                                } else {
                                    
                                    print("failed deriving processed path")
                                    completion((nil,true))
                                    
                                }
                                
                            }
                            
                        }
                        
                    } else {
                        
                        // its a watch-only wallet
                        completion((nil,true))
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func key(path: BIP32Path, completion: @escaping ((key: HDKey?, error: Bool)) -> Void) {
        
        getActiveWalletNow() { (wallet, error) in
            
            if wallet != nil && !error {
                
                let derivationPath = wallet!.derivation
                
                let enc = Encryption()
                enc.decryptData(dataToDecrypt: wallet!.seed) { (seed) in
                    
                    if String(data: wallet!.seed, encoding: .utf8) != "no seed" {
                        
                        if seed != nil {
                            
                            let words = String(data: seed!, encoding: .utf8)!
                            let mnenomicCreator = MnemonicCreator()
                            mnenomicCreator.convert(words: words) { (mnemonic, error) in
                                
                                if !error {
                                    
                                    if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivationPath)) {
                                        
                                        do {
                                            
                                            let key = try masterKey.derive(path)
                                            completion((key,false))
                                            
                                        } catch {
                                            
                                            completion((nil,true))
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((nil,true))
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((nil,true))
                                    
                                }
                                
                            }
                            
                        }
                        
                    } else {
                        
                        if wallet!.xprv != nil {
                            
                            // its a recovered wallet without a mnemonic, need to remove the account derivation as we know the psbt will return the full path
                            var processedDerivation = ""
                            let arr = "\(path)".split(separator: "/")
                            for (i, pathComponent) in arr.enumerated() {
                                
                                if i > 3 {
                                    
                                    processedDerivation += "/" + "\(pathComponent)"
                                    
                                }
                                
                                if i + 1 == arr.count {
                                    
                                    if let accountLessPath = BIP32Path(processedDerivation) {
                                        
                                        self.enc.decryptData(dataToDecrypt: wallet!.xprv!) { (decryptedXprv) in
                                            
                                            if decryptedXprv != nil {
                                                
                                                if let xprvString = String(data: decryptedXprv!, encoding: .utf8) {
                                                    
                                                    if let hdKey = HDKey(xprvString) {
                                                        
                                                        do {
                                                            
                                                            let key = try hdKey.derive(accountLessPath)
                                                            completion((key,false))
                                                            
                                                        } catch {
                                                            
                                                            completion((nil,true))
                                                            print("failed deriving child key")
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                }
                                                
                                            } else {
                                                
                                                completion((nil,true))
                                                print("failed decrypting xprv")
                                                
                                            }
                                            
                                        }
                                        
                                    } else {
                                        
                                        print("failed deriving processed path")
                                        completion((nil,true))
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                    }
                    
                }
                
            }
            
        }
        
    }
    
//    func bip32Xpub(wallet: WalletStruct, completion: @escaping ((xpub: String?, error: Bool)) -> Void) {
//
//        let derivationPath = wallet.derivation
//
//        let enc = Encryption()
//        enc.decryptData(dataToDecrypt: wallet.seed) { (seed) in
//
//            if seed != nil {
//
//                let words = String(data: seed!, encoding: .utf8)!
//                let mnenomicCreator = MnemonicCreator()
//                mnenomicCreator.convert(words: words) { (mnemonic, error) in
//
//                    if !error {
//
//                        if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivationPath)) {
//
//                            if let path = BIP32Path(derivationPath) {
//
//                                do {
//
//                                    let account = try masterKey.derive(path)
//                                    completion((account.xpub,false))
//
//                                } catch {
//
//                                    completion((nil,true))
//
//                                }
//
//                            } else {
//
//                                completion((nil,true))
//
//                            }
//
//                        } else {
//
//                            completion((nil,true))
//
//                        }
//
//                    } else {
//
//                        completion((nil,true))
//
//                    }
//
//                }
//
//            } else {
//
//                completion((nil,true))
//
//            }
//
//        }
//
//    }
    
    func xpub(wallet: WalletStruct, completion: @escaping ((xpub: String?, error: Bool)) -> Void) {
        
        let derivationPath = wallet.derivation
        let enc = Encryption()
        enc.decryptData(dataToDecrypt: wallet.seed) { (seed) in
            
            if seed != nil {
                
                let words = String(data: seed!, encoding: .utf8)!
                let mnenomicCreator = MnemonicCreator()
                mnenomicCreator.convert(words: words) { (mnemonic, error) in
                    
                    if !error {
                        
                        if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivationPath)) {
                            
                            if let path = BIP32Path(wallet.derivation) {
                                
                                do {
                                    
                                    let account = try masterKey.derive(path)
                                    completion((account.xpub,false))
                                    
                                } catch {
                                    
                                    completion((nil,true))
                                    
                                }
                                
                            } else {
                                
                                completion((nil,true))
                                
                            }
                            
                        } else {
                            
                            completion((nil,true))
                            
                        }
                        
                    } else {
                        
                        completion((nil,true))
                        
                    }
                    
                }
                
            } else {
                
                completion((nil,true))
                
            }
            
        }
        
    }
    
    func accountXpub(descriptorStruct: DescriptorStruct, completion: @escaping ((xpub: String?, error: Bool)) -> Void) {
        
        if descriptorStruct.isMulti {
            
            if descriptorStruct.multiSigKeys.count > 0 {
                
                if descriptorStruct.multiSigKeys[1] != "" {
                    
                    completion((descriptorStruct.multiSigKeys[1], false))
                    
                } else {
                    
                    completion(("", true))
                    
                }
                
            } else {
                
                completion(("", true))
                
            }
            
        } else {
           
            let xpub = descriptorStruct.accountXpub
            completion((xpub, false))
            
        }
        
    }
    
    func accountXprv(completion: @escaping ((xprv: String?, error: Bool)) -> Void) {
        
        getActiveWalletNow() { (wallet, error) in
            
            if wallet != nil && !error {
                
                let derivationPath = wallet!.derivation
                let enc = Encryption()
                enc.decryptData(dataToDecrypt: wallet!.seed) { (seed) in
                    
                    if seed != nil {
                        
                        let words = String(data: seed!, encoding: .utf8)!
                        let mnenomicCreator = MnemonicCreator()
                        mnenomicCreator.convert(words: words) { (mnemonic, error) in
                            
                            if !error {
                                
                                if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivationPath)) {
                                    
                                    if let path = BIP32Path(derivationPath) {
                                        
                                        do {
                                            
                                            let account = try masterKey.derive(path)
                                            
                                            if let xprv = account.xpriv {
                                                
                                                completion((xprv,false))
                                                
                                            } else {
                                                
                                                completion((nil,true))
                                                
                                            }
                                            
                                        } catch {
                                            
                                            completion((nil,true))
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((nil,true))
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((nil,true))
                                    
                                }
                                
                            } else {
                                
                                completion((nil,true))
                                
                            }
                            
                        }
                        
                    } else {
                        
                        completion((nil,true))
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func musigAddress(completion: @escaping ((address: String?, error: Bool)) -> Void) {
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil && !error {
                
                let reducer = Reducer()
                let index = wallet!.index + 1
                let param = "\"\(wallet!.descriptor)\", [\(index),\(index)]"
                
                reducer.makeCommand(walletName: wallet!.name, command: .deriveaddresses, param: param) {
                    
                    if !reducer.errorBool {
                        
                        self.updateIndex(wallet: wallet!)
                        
                        if let address = reducer.arrayToReturn?[0] as? String {
                            
                            completion((address,false))
                            
                        } else {
                            
                            completion((nil,true))
                            
                        }
                        
                    } else {
                        
                        print("error deriving addresses: \(reducer.errorDescription)")
                        completion((nil,true))
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func musigChangeAddress(completion: @escaping ((address: String?, error: Bool)) -> Void) {
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil && !error {
                
                let reducer = Reducer()
                let index = wallet!.index
                
                if wallet!.index < 1000 {
                    
                    let param = "\"\(wallet!.changeDescriptor)\", [\(index),\(index)]"
                    
                    reducer.makeCommand(walletName: wallet!.name, command: .deriveaddresses, param: param) {
                        
                        if !reducer.errorBool {
                            
                            if let address = reducer.arrayToReturn?[0] as? String {
                                
                                completion((address,false))
                                
                            } else {
                                
                                completion((nil,true))
                                
                            }
                            
                        } else {
                            
                            print("error deriving addresses: \(reducer.errorDescription)")
                            completion((nil,true))
                            
                        }
                        
                    }
                    
                } else {
                    
                    print("error, need to import more keys")
                    
                }
                
            }
            
        }
        
    }
    
    private func updateIndex(wallet: WalletStruct) {
        
        let cd = CoreDataService()
        cd.updateEntity(id: wallet.id, keyToUpdate: "index", newValue: wallet.index + 1, entityName: .wallets) {
            
            if cd.errorBool {
                
                print("error updating index: \(cd.errorDescription)")
                
            }
            
        }
        
    }
    
}
