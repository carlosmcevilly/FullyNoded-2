//
//  MainMenuViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit
import KeychainSwift
import LibWally
import CryptoKit

class MainMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    
    var walletExists = Bool()
    var sponsorShowing = Bool()
    let background = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    let closeButton = UIButton()
    let sponsorBanner = UIButton()
    var bootStrapping = Bool()
    var showNodeInfo = Bool()
    var torCellIndex = Int()
    var walletCellIndex = Int()
    var nodeCellIndex = Int()
    var transactionCellIndex = Int()
    var isRefreshingZero = Bool()
    var isRefreshingTorData = Bool()
    var isRefreshingTwo = Bool()
    var existingNodeId = UUID()
    var torConnected = Bool()
    var nodeSectionLoaded = Bool()
    let imageView = UIImageView()
    var statusLabel = UILabel()
    var timer:Timer!
    var wallet:WalletStruct!
    var node:NodeStruct!
    var walletInfo:HomeStruct!
    let ud = UserDefaults.standard
    var hashrateString = String()
    var version = String()
    var incomingCount = Int()
    var outgoingCount = Int()
    var isPruned = Bool()
    var tx = String()
    var currentBlock = Int()
    var transactionArray = [[String:Any]]()
    @IBOutlet var mainMenu: UITableView!
    var refresher: UIRefreshControl!
    var connectingView = ConnectingView()
    let cd = CoreDataService()
    let enc = Encryption()
    var nodes = [[String:Any]]()
    var uptime = Int()
    var initialLoad = Bool()
    var mempoolCount = Int()
    var walletDisabled = Bool()
    var torReachable = Bool()
    var progress = ""
    var difficulty = ""
    var feeRate = ""
    var size = ""
    var coldBalance = ""
    var unconfirmedBalance = ""
    var network = ""
    var p2pOnionAddress = ""
    var walletSectionLoaded = Bool()
    var torSectionLoaded = Bool()
    let spinner = UIActivityIndicatorView(style: .medium)
    var dataRefresher = UIBarButtonItem()
    var wallets = NSArray()
    let label = UILabel()
    var existingWalletName = ""
    var fiatBalance = ""
    var transactionsSectionLoaded = Bool()
    var infoHidden = Bool()
    var torInfoHidden = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        torConnected = false
        mainMenu.delegate = self
        tabBarController?.delegate = self
        navigationController?.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(torBootStrapping(_:)), name: .didStartBootstrappingTor, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didCompleteOnboarding(_:)), name: .didCompleteOnboarding, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(torConnected(_:)), name: .didEstablishTorConnection, object: nil)
        
        initialLoad = true
        walletSectionLoaded = false
        torSectionLoaded = false
        nodeSectionLoaded = false
        transactionsSectionLoaded = false
        isRefreshingTorData = true
        setTitleView()
        configureRefresher()
        infoHidden = true
        torInfoHidden = true
        showNodeInfo = false
        
        if ud.object(forKey: "firstTime") == nil {
            
            firstTimeHere()
            
        }
        
        enc.getNode { (node, error) in
            
            if !error && node != nil {
                
                self.node = node!
                self.existingNodeId = node!.id
                
                getActiveWalletNow() { (wallet, error) in
                    
                    if !error && wallet != nil {
                        
                        self.wallet = wallet
                        self.existingWalletName = wallet!.name
                                                
                    }
                    
                }
                
            }
            
        }
        
        bootStrapping = true
        addStatusLabel(description: "     Bootstrapping Tor...")
        reloadSections([torCellIndex])
                    
    }
    
    private func goToIntro() {
        
        func showIntro() {
            
            DispatchQueue.main.async {
                
                self.performSegue(withIdentifier: "showIntro", sender: self)
                
            }
            
        }
        
        let keychain = KeychainSwift()
                
        if ud.object(forKey: "acceptedDisclaimer1") == nil || keychain.get("userIdentifier") == nil {
            
            ud.set(false, forKey: "acceptedDisclaimer1")
            showIntro()
            
        } else if ud.object(forKey: "acceptedDisclaimer1") as! Bool == false {
            
            showIntro()
            
        }
        
    }
    
    @IBAction func goToSettings(_ sender: Any) {
        
        impact()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "settings", sender: self)
            
        }
        
    }
    
    @objc func didCompleteOnboarding(_ notification: Notification) {
        
        didAppear()
        
    }
    
    @objc func torBootStrapping(_ notification: Notification) {
        print("torBootStrapping")
        
        bootStrapping = true
        addStatusLabel(description: "     Bootstrapping Tor...")
        reloadSections([torCellIndex])
        
    }
    
    @objc func torConnected(_ notification: Notification) {
        
        bootStrapping = false
        torConnected = true
        reloadSections([torCellIndex])
        didAppear()
        
    }
    
    @IBAction func goToWallets(_ sender: Any) {
        
        impact()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "scanNow", sender: self)
            
        }
        
    }
    
    @objc func walletsSegue() {
        
        impact()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "goToWallets", sender: self)
            
        }
        
    }
    
    private func setTitleView() {
        
        let imageView = UIImageView(image: UIImage(named: "1024.png"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        imageView.frame = titleView.bounds
        imageView.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(logoTapped))
        imageView.addGestureRecognizer(tapRecognizer)
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        goToIntro()
        didAppear()
        
    }
    
    @objc func logoTapped() {
        
        impact()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "goDonate", sender: self)
            
        }
        
    }
    
    private func didAppear() {
        print("didappear")
                
        DispatchQueue.main.async {
            
            self.enc.getNode { (node, error) in
                
                if !error && node != nil {
                                        
                    self.node = node!
                    
                    if self.torConnected {
                        
                        if self.initialLoad {
                            
                            self.initialLoad = false
                            self.reloadTableData()
                            
                        } else {
                            
                            getActiveWalletNow() { (w, error) in
                                                                
                                if !error && w != nil {
                                    
                                    self.wallet = w!
                                                                        
                                    if w!.index >= w!.maxRange - 100 {
                                        
                                        self.showIndexWarning()
                                        
                                    }
                                    
                                    if self.existingWalletName != w!.name && self.existingNodeId != node!.id {
                                        
                                        self.existingNodeId = node!.id
                                        self.refreshNow()
                                        
                                    } else if self.existingWalletName != w!.name {
                                        
                                        self.loadWalletData()
                                        
                                    }
                                    
                                } else {
                                    
                                    self.existingWalletName = ""
                                    
                                    if self.existingNodeId != node!.id {
                                        
                                        self.refreshNow()
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    self.addNode()
                    
                }
                
            }
                        
        }

    }
    
    private func showIndexWarning() {
        
        var message = ""
        var actionTitle = ""
        var alertAction: (() -> Void)!
        
        if self.wallet.type == "MULTI" {
            
            message = "Your node only has \(self.wallet.maxRange - self.wallet.index) more keys left to sign with. We urge you to roll this wallet over to a new one ASAP. If you exeed the limit the your node will no longer be able to sign this wallets transactions."
            actionTitle = "Roll Over"
            
            alertAction = {
                
                print("roll over")
                
            }
            
        } else {
            
            message = "Your node only has \(self.wallet.maxRange - self.wallet.index) more public keys. We need to import more public keys into your node at this point to ensure your node is able to verify this wallets balances and build psbt's for us."
            actionTitle = "Refill Keypool"
            
            alertAction = {
                
                print("refill keypool")
                
            }
            
        }
        
        DispatchQueue.main.async {
                        
            let alert = UIAlertController(title: "Warning!", message: message, preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { action in
                
                alertAction()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    private func setFeeTarget() {
        
        if ud.object(forKey: "feeTarget") == nil {
            
            ud.set(432, forKey: "feeTarget")
            
        }
        
    }
    
    //MARK: Tableview Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if transactionArray.count > 0 {
            
            return 3 + transactionArray.count
            
        } else {
            
            return 4
            
        }
                
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    private func spinningCell() -> UITableViewCell {
        
        let blank = blankCell()
        let spinner = UIActivityIndicatorView()
        spinner.frame = CGRect(x: mainMenu.frame.maxX - 80, y: (blank.frame.height / 2) - 10, width: 20, height: 20)
        blank.addSubview(spinner)
        spinner.startAnimating()
        return blank
        
    }
    
    private func blankCell() -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = #colorLiteral(red: 0.05172085258, green: 0.05855310153, blue: 0.06978280196, alpha: 1)
        return cell
        
    }
    
    private func descriptionCell(description: String) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = #colorLiteral(red: 0.05172085258, green: 0.05855310153, blue: 0.06978280196, alpha: 1)
        cell.textLabel?.text = description
        cell.textLabel?.textColor = .lightGray
        return cell
        
    }
    
    private func noActiveWalletCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = descriptionCell(description: "⚠︎ No active wallet")
        let addWalletButton = UIButton()
        addWalletButton.frame = CGRect(x: mainMenu.frame.maxX - 80, y: (cell.frame.height / 2) - 10, width: 20, height: 20)
        addWalletButton.addTarget(self, action: #selector(addWallet), for: .touchUpInside)
        let image = UIImage(systemName: "plus")
        addWalletButton.setImage(image, for: .normal)
        addWalletButton.tintColor = .systemBlue
        cell.addSubview(addWalletButton)
        return cell
        
    }
    
    private func defaultWalletCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "singleSigCell", for: indexPath)
        cell.selectionStyle = .none
        
        let walletNameLabel = cell.viewWithTag(1) as! UILabel
        let coldBalanceLabel = cell.viewWithTag(2) as! UILabel
        let walletTypeLabel = cell.viewWithTag(4) as! UILabel
        let derivationPathLabel = cell.viewWithTag(5) as! UILabel
        let seedOnDeviceLabel = cell.viewWithTag(8) as! UILabel
        let dirtyFiatLabel = cell.viewWithTag(11) as! UILabel
        let infoButton = cell.viewWithTag(12) as! UIButton
        let deviceXprv = cell.viewWithTag(15) as! UILabel
        let deviceView = cell.viewWithTag(16)!
        //let refreshingSpinner = cell.viewWithTag(23) as! UIActivityIndicatorView
        let nodeView = cell.viewWithTag(24)!
        let keysOnNodeDescription = cell.viewWithTag(25) as! UILabel
        let confirmedIcon = cell.viewWithTag(26) as! UIImageView
        
        coldBalanceLabel.isUserInteractionEnabled = true
        let tap = UIGestureRecognizer()
        tap.addTarget(self, action: #selector(switchBalances(_:)))
        
        nodeView.layer.cornerRadius = 8
        
//        if isRefreshingZero {
//
//            refreshingSpinner.alpha = 1
//            refreshingSpinner.startAnimating()
//
//        } else {
//
//            refreshingSpinner.alpha = 0
//            refreshingSpinner.stopAnimating()
//        }
        
        deviceView.layer.cornerRadius = 8
        infoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
        
        if infoHidden {
            
            let image = UIImage(systemName: "rectangle.expand.vertical")
            infoButton.setImage(image, for: .normal)
            
        } else {
            
            let image = UIImage(systemName: "rectangle.compress.vertical")
            infoButton.setImage(image, for: .normal)
            
        }
        
        self.coldBalance = walletInfo.coldBalance
                        
        if coldBalance == "" {
            
            self.coldBalance = "0"
            
        }
        
        dirtyFiatLabel.text = "\(self.fiatBalance)"
        
        let parser = DescriptorParser()
        let str = parser.descriptor(wallet.descriptor)
        
        if str.chain == "Mainnet" {
            
            coldBalanceLabel.textColor = .systemGreen
            
        } else if str.chain == "Testnet" {
            
            coldBalanceLabel.textColor = .systemOrange
            
        }
        
        if wallet.type == "CUSTOM" {
            
            coldBalanceLabel.textColor = .systemGray
        }
                            
        coldBalanceLabel.text = self.coldBalance
        
        if walletInfo.unconfirmed {
            
            confirmedIcon.image = UIImage(systemName: "exclamationmark.triangle")
            confirmedIcon.tintColor = .systemRed
            
        } else {
            
            confirmedIcon.image = UIImage(systemName: "checkmark")
            confirmedIcon.tintColor = .systemGreen
            
        }
        
        if walletInfo.noUtxos {
            
            confirmedIcon.alpha = 0
            
        } else {
            
            confirmedIcon.alpha = 1
            
        }
        
        coldBalanceLabel.adjustsFontSizeToFitWidth = true
        
        walletTypeLabel.text = "Single Signature"
        seedOnDeviceLabel.text = "1 Signer on \(UIDevice.current.name)"
        
        if wallet.derivation.contains("84") {
            
            derivationPathLabel.text = "Native Segwit Account 0 (BIP84 \(wallet.derivation))"
            
        } else if wallet.derivation.contains("44") {
            
            derivationPathLabel.text = "Legacy Account 0 (BIP44 \(wallet.derivation))"
            
        } else if wallet.derivation.contains("49") {
            
            derivationPathLabel.text = "P2SH Nested Segwit Account 0 (BIP49 \(wallet.derivation))"
            
        }
        
        keysOnNodeDescription.text = "public keys \(wallet.derivation)/0 to /\(wallet.maxRange)"
        deviceXprv.text = "xprv \(wallet.derivation)"
        walletNameLabel.text = reducedName(name: wallet.name)
        
        return cell
        
    }
    
    private func multiWalletCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "walletCell", for: indexPath)
        cell.selectionStyle = .none
        
        let walletNameLabel = cell.viewWithTag(1) as! UILabel
        let coldBalanceLabel = cell.viewWithTag(2) as! UILabel
        let walletTypeLabel = cell.viewWithTag(4) as! UILabel
        let derivationPathLabel = cell.viewWithTag(5) as! UILabel
        let backUpSeedLabel = cell.viewWithTag(6) as! UILabel
        let seedOnNodeLabel = cell.viewWithTag(7) as! UILabel
        let seedOnDeviceLabel = cell.viewWithTag(8) as! UILabel
        let dirtyFiatLabel = cell.viewWithTag(11) as! UILabel
        let infoButton = cell.viewWithTag(12) as! UIButton
        let deviceXprv = cell.viewWithTag(15) as! UILabel
        let deviceView = cell.viewWithTag(16)!
        let nodeXprv = cell.viewWithTag(17) as! UILabel
        let nodeView = cell.viewWithTag(18)!
        let offlineView = cell.viewWithTag(19)!
        let offlineXprvLabel = cell.viewWithTag(22) as! UILabel
        //let refreshingSpinner = cell.viewWithTag(23) as! UIActivityIndicatorView
        let confirmedIcon = cell.viewWithTag(26) as! UIImageView
        
        coldBalanceLabel.isUserInteractionEnabled = true
        let tap = UIGestureRecognizer()
        tap.addTarget(self, action: #selector(switchBalances(_:)))
        
//        if isRefreshingZero {
//
//            refreshingSpinner.alpha = 1
//            refreshingSpinner.startAnimating()
//
//        } else {
//
//            refreshingSpinner.alpha = 0
//            refreshingSpinner.stopAnimating()
//        }
        
        nodeView.layer.cornerRadius = 8
        offlineView.layer.cornerRadius = 8
        deviceView.layer.cornerRadius = 8
        
        infoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
        
        if infoHidden {
            
            let image = UIImage(systemName: "rectangle.expand.vertical")
            infoButton.setImage(image, for: .normal)
            
        } else {
            
            let image = UIImage(systemName: "rectangle.compress.vertical")
            infoButton.setImage(image, for: .normal)
            
        }
        
        self.coldBalance = walletInfo.coldBalance
                        
        if coldBalance == "" {
            
            self.coldBalance = "0"
            
        }
        
        dirtyFiatLabel.text = "\(self.fiatBalance)"
        
        let parser = DescriptorParser()
        let str = parser.descriptor(wallet.descriptor)
        
        if str.chain == "Mainnet" {
            
            coldBalanceLabel.textColor = .systemGreen
            
        } else if str.chain == "Testnet" {
            
            coldBalanceLabel.textColor = .systemOrange
            
        }
        
        coldBalanceLabel.text = self.coldBalance
        
        if walletInfo.unconfirmed {
            
            confirmedIcon.image = UIImage(systemName: "exclamationmark.triangle")
            confirmedIcon.tintColor = .systemRed
            
        } else {
            
            confirmedIcon.image = UIImage(systemName: "checkmark")
            confirmedIcon.tintColor = .systemGreen
            
        }
        
        if walletInfo.noUtxos {
            
            confirmedIcon.alpha = 0
            
        } else {
            
            confirmedIcon.alpha = 1
            
        }
        
        coldBalanceLabel.adjustsFontSizeToFitWidth = true
        
        walletTypeLabel.text = "2 of 3 multisig"
        backUpSeedLabel.text = "1 Seed Offline"
        seedOnNodeLabel.text = "1 Seedless \(node.label)"
        seedOnDeviceLabel.text = "1 Seed on \(UIDevice.current.name)"
        nodeView.alpha = 1
        offlineView.alpha = 1
        
        if wallet.derivation.contains("84") {
            
            derivationPathLabel.text = "Native Segwit Account 0 (BIP84 \(wallet.derivation))"
            
        } else if wallet.derivation.contains("44") {
            
            derivationPathLabel.text = "Legacy Account 0 (BIP44 \(wallet.derivation))"
            
        } else if wallet.derivation.contains("49") {
            
            derivationPathLabel.text = "P2SH Nested Segwit Account 0 (BIP49 \(wallet.derivation))"
            
        }
        
        nodeXprv.text = "keys \(wallet.derivation)/0 and 1/0 to /\(wallet.maxRange)"
        deviceXprv.text = "xprv \(wallet.derivation)"
        offlineXprvLabel.text = "xprv \(wallet.derivation)"
        
        walletNameLabel.text = reducedName(name: wallet.name)
        
        return cell
        
    }
    
    private func customWalletCell(_ indexPath: IndexPath) -> UITableViewCell {
     
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "coldStorageCell", for: indexPath)
        cell.selectionStyle = .none
        
        let descriptorParser = DescriptorParser()
        let descStruct = descriptorParser.descriptor(wallet.descriptor)
        
        let walletNameLabel = cell.viewWithTag(1) as! UILabel
        let coldBalanceLabel = cell.viewWithTag(2) as! UILabel
        let walletTypeLabel = cell.viewWithTag(4) as! UILabel
        let derivationPathLabel = cell.viewWithTag(5) as! UILabel
        let seedOnDeviceLabel = cell.viewWithTag(8) as! UILabel
        let dirtyFiatLabel = cell.viewWithTag(11) as! UILabel
        let infoButton = cell.viewWithTag(12) as! UIButton
        //let refreshingSpinner = cell.viewWithTag(23) as! UIActivityIndicatorView
        let nodeView = cell.viewWithTag(24)!
        let watchIcon = cell.viewWithTag(25) as! UIImageView
        let keysOnNodeLabel = cell.viewWithTag(26) as! UILabel
        let confirmedIcon = cell.viewWithTag(27) as! UIImageView
        
        coldBalanceLabel.isUserInteractionEnabled = true
        let tap = UIGestureRecognizer()
        tap.addTarget(self, action: #selector(switchBalances(_:)))
        
        nodeView.layer.cornerRadius = 8
        
//        if isRefreshingZero {
//
//            refreshingSpinner.alpha = 1
//            refreshingSpinner.startAnimating()
//
//        } else {
//
//            refreshingSpinner.alpha = 0
//            refreshingSpinner.stopAnimating()
//        }
        
        
        infoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
        
        if infoHidden {
            
            let image = UIImage(systemName: "rectangle.expand.vertical")
            infoButton.setImage(image, for: .normal)
            
        } else {
            
            let image = UIImage(systemName: "rectangle.compress.vertical")
            infoButton.setImage(image, for: .normal)
            
        }
        
        self.coldBalance = walletInfo.coldBalance
        
        if coldBalance == "" {
            
            self.coldBalance = "0"
            
        }
        
        dirtyFiatLabel.text = "\(self.fiatBalance)"
        
        let parser = DescriptorParser()
        let str = parser.descriptor(wallet.descriptor)
        
        if str.chain == "Mainnet" {
            
            coldBalanceLabel.textColor = .systemGreen
            
        } else if str.chain == "Testnet" {
            
            coldBalanceLabel.textColor = .systemOrange
            
        }
        
        coldBalanceLabel.text = self.coldBalance
        
        if walletInfo.unconfirmed {
            
            confirmedIcon.image = UIImage(systemName: "exclamationmark.triangle")
            confirmedIcon.tintColor = .systemRed
            
        } else {
            
            confirmedIcon.image = UIImage(systemName: "checkmark")
            confirmedIcon.tintColor = .systemGreen
            
        }
        
        if walletInfo.noUtxos {
            
            confirmedIcon.alpha = 0
            
        } else {
            
            confirmedIcon.alpha = 1
            
        }
                
        coldBalanceLabel.adjustsFontSizeToFitWidth = true
        
        if descStruct.isMulti {
            
            walletTypeLabel.text = descStruct.mOfNType
            
        } else {
            
            walletTypeLabel.text = "Single Signature"
            
        }
        
        if descStruct.isHot {
            
            seedOnDeviceLabel.text = "\(node.label) is Hot"
            keysOnNodeLabel.text = "\(wallet.maxRange) private keys on \(node.label)"
            watchIcon.image = UIImage(systemName: "pencil.and.ellipsis.rectangle")
            
        } else {
            
            seedOnDeviceLabel.text = "\(node.label) is Cold"
            keysOnNodeLabel.text = "\(wallet.maxRange) public keys on \(node.label)"
            watchIcon.image = UIImage(systemName: "eye")
            
        }
        
        
        derivationPathLabel.text = descStruct.format
        
        walletNameLabel.text = reducedName(name: wallet.name)
        
        return cell
        
    }
    
    private func torCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "torCell", for: indexPath)
        cell.selectionStyle = .none
        let torStatusLabel = cell.viewWithTag(1) as! UILabel
        let p2pOnionLabel = cell.viewWithTag(3) as! UILabel
        let onionVersionLabel = cell.viewWithTag(4) as! UILabel
        let v3address = cell.viewWithTag(6) as! UILabel
        let torActiveCircle = cell.viewWithTag(7) as! UIImageView
        //let spinner = cell.viewWithTag(8) as! UIActivityIndicatorView
        let infoButton = cell.viewWithTag(9) as! UIButton
        let connectedView = cell.viewWithTag(10)!
        let clientOnionView = cell.viewWithTag(11)!
        let excludeExitView = cell.viewWithTag(12)!
        let p2pView = cell.viewWithTag(13)!
        let v3OnionView = cell.viewWithTag(14)!
        let v3View = cell.viewWithTag(15)!
        
        v3View.layer.cornerRadius = 8
        connectedView.layer.cornerRadius = 8
        clientOnionView.layer.cornerRadius = 8
        excludeExitView.layer.cornerRadius = 8
        p2pView.layer.cornerRadius = 8
        v3OnionView.layer.cornerRadius = 8
        
        spinner.startAnimating()
        spinner.alpha = 1
        infoButton.alpha = 0
        infoButton.addTarget(self, action: #selector(getTorInfo(_:)), for: .touchUpInside)
        
        if torInfoHidden {
            
            let image = UIImage(systemName: "rectangle.expand.vertical")
            infoButton.setImage(image, for: .normal)
            
        } else {
            
            let image = UIImage(systemName: "rectangle.compress.vertical")
            infoButton.setImage(image, for: .normal)
            
        }
        
        let onionAddress = (node.onionAddress.split(separator: "."))[0]
        
        if onionAddress.count == 16 {
            
            onionVersionLabel.text = "bitcoin core rpc hidden service version 2"
            
        } else if onionAddress.count == 56 {
            
            onionVersionLabel.text = "bitcoin core rpc hidden service version 3"
            
        }
        
        if isRefreshingTorData {
            
            spinner.startAnimating()
            spinner.alpha = 1
            infoButton.alpha = 0
            
        } else {
            
            spinner.stopAnimating()
            spinner.alpha = 0
            infoButton.alpha = 1
            
        }
        
        let first10 = String(node.onionAddress.prefix(5))
        let last15 = String(node.onionAddress.suffix(15))
        v3address.text = "💻 ← \(first10)*****\(last15) → 📱"
        
        if torSectionLoaded {
            
            p2pOnionLabel.text = "P2P URL: \(p2pOnionAddress)"
            
        } else {
            
            p2pOnionLabel.text = "fetching network info from your node..."
            
        }
        
        torActiveCircle.image = UIImage(systemName: "circle.fill")
        
        if self.torConnected {
            
            if torSectionLoaded && !isRefreshingTorData {
                
                spinner.stopAnimating()
                spinner.alpha = 0
                infoButton.alpha = 1
                torStatusLabel.text = "\(node.label)"
                torActiveCircle.tintColor = .systemGreen
                
            } else if isRefreshingTorData && !torSectionLoaded {
                
                spinner.startAnimating()
                spinner.alpha = 1
                infoButton.alpha = 0
                torStatusLabel.text = "\(node.label)..."
                torActiveCircle.tintColor = .systemOrange
                
            }
            
        } else {
            
            if bootStrapping {
                
                spinner.startAnimating()
                spinner.alpha = 1
                infoButton.alpha = 0
                torStatusLabel.text = "bootstrapping..."
                torActiveCircle.tintColor = .systemOrange
                
            } else {
                
                torStatusLabel.text = "\(node.label)..."
                torActiveCircle.tintColor = .systemRed
                spinner.stopAnimating()
                spinner.alpha = 0
                infoButton.alpha = 1
                
            }
            
        }
        
        return cell
        
    }
    
    private func nodeCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "NodeInfo", for: indexPath)
        cell.selectionStyle = .none
        cell.isSelected = false
        
        let network = cell.viewWithTag(1) as! UILabel
        let pruned = cell.viewWithTag(2) as! UILabel
        let connections = cell.viewWithTag(3) as! UILabel
        let version = cell.viewWithTag(4) as! UILabel
        let hashRate = cell.viewWithTag(5) as! UILabel
        let sync = cell.viewWithTag(6) as! UILabel
        let blockHeight = cell.viewWithTag(7) as! UILabel
        let uptime = cell.viewWithTag(8) as! UILabel
        let mempool = cell.viewWithTag(10) as! UILabel
        let tor = cell.viewWithTag(11) as! UILabel
        let difficultyLabel = cell.viewWithTag(12) as! UILabel
        let sizeLabel = cell.viewWithTag(13) as! UILabel
        let feeRate = cell.viewWithTag(14) as! UILabel
        let isHot = cell.viewWithTag(15) as! UILabel
        //let refreshingSpinner = cell.viewWithTag(16) as! UIActivityIndicatorView
        let infoButton = cell.viewWithTag(17) as! UIButton
        
        infoButton.addTarget(self, action: #selector(getNodeInfo(_:)), for: .touchUpInside)
        
        if !showNodeInfo {
            
            let image = UIImage(systemName: "rectangle.expand.vertical")
            infoButton.setImage(image, for: .normal)
            
        } else {
            
            let image = UIImage(systemName: "rectangle.compress.vertical")
            infoButton.setImage(image, for: .normal)
            
        }
        
        network.layer.cornerRadius = 6
        pruned.layer.cornerRadius = 6
        connections.layer.cornerRadius = 6
        version.layer.cornerRadius = 6
        hashRate.layer.cornerRadius = 6
        sync.layer.cornerRadius = 6
        blockHeight.layer.cornerRadius = 6
        uptime.layer.cornerRadius = 6
        mempool.layer.cornerRadius = 6
        tor.layer.cornerRadius = 6
        difficultyLabel.layer.cornerRadius = 6
        sizeLabel.layer.cornerRadius = 6
        feeRate.layer.cornerRadius = 6
        isHot.layer.cornerRadius = 6
        
//        if isRefreshingTwo {
//
//            refreshingSpinner.alpha = 1
//            refreshingSpinner.startAnimating()
//
//        } else {
//
//            refreshingSpinner.alpha = 0
//            refreshingSpinner.stopAnimating()
//        }
        
        sizeLabel.text = "\(self.size) size"
        difficultyLabel.text = "\(self.difficulty) difficulty"
        
        if self.progress == "99%" {
            
            sync.text = "fully synced"
            
        } else {
            
            sync.text = "\(self.progress) synced"
            
        }
        
        feeRate.text = "\(self.feeRate) fee rate"
        
        isHot.textColor = .white
        
        if wallet != nil {
            
            isHot.alpha = 1
            
            if wallet.type == "DEFAULT" {
                
                isHot.text = "watch-only"
                isHot.textColor = .systemBlue
                
            } else if wallet.type == "MULTI" {
                
                isHot.text = "signer"
                isHot.textColor = .systemTeal
                
            } else if wallet.type == "CUSTOM" {
                
                isHot.text = "watch-only"
                
                let parser = DescriptorParser()
                let str = parser.descriptor(wallet.descriptor)
                
                if str.isHot {
                    
                    isHot.textColor = .systemTeal
                    
                } else {
                    
                    isHot.textColor = .systemBlue
                    
                }
                
            }
            
        } else {
            
            isHot.alpha = 0
            
        }
        
        if torReachable {
            
            tor.text = "Tor on"
            
        } else {
            
            tor.text = "Tor off"
            
        }
        
        mempool.text = "\(self.mempoolCount.withCommas()) mempool"
        
        if self.isPruned {
            
            pruned.text = "pruned"
            
        } else if !self.isPruned {
            
            pruned.text = "not pruned"
        }
        
        if self.network != "" {
            
            if self.network == "main" {
                
                network.text = "mainnet"
                network.textColor = .systemGreen
                
            } else if self.network == "test" {
                
                network.text = "⚠ testnet"
                network.textColor = .systemOrange
                
            } else {
                
                network.text = self.network
                
            }
            
        }
        
        blockHeight.text = "\(self.currentBlock.withCommas()) blocks"
        connections.text = "\(incomingCount) ↓ \(outgoingCount) ↑ connections"
        version.text = "Bitcoin Core v\(self.version)"
        hashRate.text = self.hashrateString + " " + "EH/s hashrate"
        uptime.text = "\(self.uptime / 86400) days uptime"
        
        return cell
        
    }
    
    private func transactionCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "MainMenuCell", for: indexPath)
        cell.selectionStyle = .none
        mainMenu.separatorColor = .darkGray
        
        let amountLabel = cell.viewWithTag(2) as! UILabel
        let confirmationsLabel = cell.viewWithTag(3) as! UILabel
        let labelLabel = cell.viewWithTag(4) as! UILabel
        let dateLabel = cell.viewWithTag(5) as! UILabel
        let infoButton = cell.viewWithTag(6) as! UIButton
        
        infoButton.addTarget(self, action: #selector(getTransaction(_:)), for: .touchUpInside)
        infoButton.restorationIdentifier = "\( indexPath.section)"
        amountLabel.alpha = 1
        confirmationsLabel.alpha = 1
        labelLabel.alpha = 1
        dateLabel.alpha = 1
        
        let dict = self.transactionArray[indexPath.section - 3]
                        
        confirmationsLabel.text = (dict["confirmations"] as! String) + " " + "confs"
        let label = dict["label"] as? String
        
        if label != "," {
            
            labelLabel.text = label
            
        } else if label == "," {
            
            labelLabel.text = ""
            
        }
        
        dateLabel.text = dict["date"] as? String
        
        if dict["abandoned"] as? Bool == true {
            
            cell.backgroundColor = UIColor.red
            
        }
        
        let amount = dict["amount"] as! String
        let confs = Int(dict["confirmations"] as! String)!
        
        if confs == 0 {
            
            confirmationsLabel.textColor = .systemRed
            
        } else if confs < 6 {
         
            confirmationsLabel.textColor = .systemYellow
            
        } else {
            
            confirmationsLabel.textColor = .systemGray
            
        }
        
        let selfTransfer = dict["selfTransfer"] as! Bool
        
        if amount.hasPrefix("-") {
        
            amountLabel.text = amount
            amountLabel.textColor = .darkGray
            labelLabel.textColor = .systemGray
            dateLabel.textColor = .systemGray
            
        } else {
            
            amountLabel.text = "+" + amount
            amountLabel.textColor = .lightGray
            labelLabel.textColor = .systemGray
            dateLabel.textColor = .systemGray
                                
        }
        
        if selfTransfer {
            
            amountLabel.text = (amountLabel.text!).replacingOccurrences(of: "+", with: "🔄")
            amountLabel.text = (amountLabel.text!).replacingOccurrences(of: "-", with: "🔄")
            
        }
        
        if confs == 0 {
            
            amountLabel.text = "⚠︎ \(amountLabel.text!)"
            
        }
        
        return cell
        
    }
    
    private func walletCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        self.walletCellIndex = indexPath.section
        
        if walletSectionLoaded {
            
            if walletExists {
                
                let type = wallet.type
                
                switch type {
                    
                // Single sig wallet
                case "DEFAULT":
                    return defaultWalletCell(indexPath)
                    
                // Multi sig wallet
                case "MULTI":
                    return multiWalletCell(indexPath)
                    
                // Custom wallet (can be antyhing the user imports), to parse it we use the DescriptorParser.swift
                case "CUSTOM":
                    return customWalletCell(indexPath)
                    
                default:
                    return blankCell()
                }
                
            } else {
                
                return blankCell()
                
            }
            
        } else {
            
            if torSectionLoaded && self.node != nil && self.wallet != nil && self.torConnected {
                
                return spinningCell()
                
            } else if torSectionLoaded && wallet == nil && self.torConnected {
                
                return noActiveWalletCell(indexPath)
                
            } else {
                
                return blankCell()
                
            }
            
        }
        
    }
    
    private func torsCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        self.torCellIndex = indexPath.section
        
        if !torConnected {
            
            return descriptionCell(description: "⚠︎ Tor not connected")
            
        } else {
            
            if node != nil {
                
                if !torSectionLoaded {
                    
                    return spinningCell()
                    
                } else {
                    
                    return torCell(indexPath)
                    
                }
                            
            } else {
                
                return blankCell()
                
            }
            
        }
        
    }
    
    private func nodesCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        self.nodeCellIndex = indexPath.section
        
        if nodeSectionLoaded {
            
            return nodeCell(indexPath)
            
        } else if torSectionLoaded {
                
            return spinningCell()
                
        } else {
            
            return blankCell()
            
        }
        
    }
    
    private func transactionsCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        self.transactionCellIndex = indexPath.section
     
        if !transactionsSectionLoaded {
            
            if walletSectionLoaded {
                
                return spinningCell()
                
            } else if self.wallet == nil && nodeSectionLoaded {
                
                return descriptionCell(description: "⚠︎ No active wallet")
                
            } else if self.wallet != nil && nodeSectionLoaded {
                
                return descriptionCell(description: "⚠︎ No transactions")
                
            } else {
                
                return blankCell()
                
            }
                                
        } else {
            
            if transactionArray.count > 0 {
                
                return transactionCell(indexPath)
                
            } else if self.wallet == nil {
                
                return descriptionCell(description: "⚠︎ No active wallet")
                
            } else {
                
                return descriptionCell(description: "No transactions")
                
            }
                               
        }
        
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
        switch indexPath.section {
            
        case 0:
            
            return torsCell(indexPath)
            
        case 1:
                        
            return nodesCell(indexPath)
            
        case 2:
            
            return walletCell(indexPath)
            
        default:
            
            return transactionsCell(indexPath)
                        
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
                
        let header = UIView()
        header.backgroundColor = UIColor.clear
        header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 30)
        
        let textLabel = UILabel()
        textLabel.textAlignment = .left
        textLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        textLabel.textColor = .systemGray
        
        let refreshButton = UIButton()
        let image = UIImage(systemName: "arrow.clockwise")
        refreshButton.setImage(image, for: .normal)
        refreshButton.tintColor = .white
        refreshButton.tag = section
        refreshButton.addTarget(self, action: #selector(reloadSection(_:)), for: .touchUpInside)
        let refreshButtonX = header.frame.maxX - 32
        
        switch section {
            
        case self.torCellIndex:
            
            //if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: self.torCellIndex)) {
                
                textLabel.text = "Tor Status"
                
                if torSectionLoaded {
                    
                    refreshButton.alpha = 1
                    refreshButton.frame = CGRect(x: refreshButtonX, y: 0, width: 15, height: 18)
                    textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
                    
                } else {
                    
                    refreshButton.alpha = 0
                    refreshButton.frame = CGRect(x: 0, y: 0, width: 15, height: 18)
                    textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
                    
                }
                
            //}
            
        case self.walletCellIndex:
            
            //if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: self.walletCellIndex)) {
                
                textLabel.text = "Active Wallet Info"
                
                if walletSectionLoaded {
                    
                    refreshButton.alpha = 1
                    refreshButton.frame = CGRect(x: refreshButtonX, y: 0, width: 15, height: 18)
                    textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
                    
                } else {
                    
                    refreshButton.alpha = 0
                    refreshButton.frame = CGRect(x: 0, y: 0, width: 15, height: 18)
                    textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
                    
                }
                
            //}
            
        case self.nodeCellIndex:
            
            //let cell = tableView.cellForRow(at: IndexPath(row: 0, section: self.nodeCellIndex))
                
            textLabel.text = "Full Node Status"
            
            if nodeSectionLoaded {
                
                refreshButton.alpha = 1
                refreshButton.frame = CGRect(x: refreshButtonX, y: 0, width: 15, height: 18)
                textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
                
            } else {
                
                refreshButton.alpha = 0
                refreshButton.frame = CGRect(x: 0, y: 0, width: 15, height: 18)
                textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
                
            }
            
        case 3:
            
            //if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) {
                
                textLabel.text = "Transaction History"
                
                if transactionsSectionLoaded {
                    
                    refreshButton.alpha = 1
                    refreshButton.frame = CGRect(x: refreshButtonX, y: 0, width: 15, height: 18)
                    textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
                    
                } else {
                    
                    refreshButton.alpha = 0
                    refreshButton.frame = CGRect(x: 0, y: 0, width: 15, height: 18)
                    textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
                    
                }
                
            //}
            
        default:
            
            break
            
        }
        
        refreshButton.center.y = textLabel.center.y
        header.addSubview(textLabel)
        header.addSubview(refreshButton)
        
        return header
        
    }
    
    @objc func reloadSection(_ sender: UIButton) {
        
        impact()
        let section = sender.tag
        sender.tintColor = .clear
        sender.loadingIndicator(show: true)
        
        switch section {
            
        case self.torCellIndex:
            
            self.refreshTorData(sender)
            
        case self.walletCellIndex:
            
            self.refreshWalletData(sender)
            
        case self.nodeCellIndex:
            
            self.refreshNodeData(sender)
            
        default:
            
            self.refreshTransactions(sender)
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section <= 3 {
            
            return 30
            
        } else {
            
            return 10
            
        }
                
    }
    
    private func walletCellHeight() -> CGFloat {
        
        if walletSectionLoaded {
            
            if wallet.type == "MULTI" {
                
                if infoHidden {
                    
                    return 114
                    
                } else {
                   
                    return 290
                    
                }
                
            } else if wallet.type == "CUSTOM" {
                
                if infoHidden {
                
                    return 114
                    
                } else {
                    
                    return 188
                    
                }
                
            } else {
                
                if infoHidden {
                
                    return 114
                    
                } else {
                    
                    return 255
                    
                }
                
            }

        } else {

            return 47

        }
        
    }
    
    private func torCellHeight() -> CGFloat {
        
        if !torConnected {
            
            return 47
            
        } else {
            
            if self.node != nil {
                
                if torInfoHidden {
                    
                    if torSectionLoaded {
                        
                        return 85
                        
                    } else {
                        
                        return 47
                        
                    }
                    
                } else {
                    
                    return 165
                    
                }
                
            } else {
                
                return 47
                
            }
            
        }
        
    }
    
    private func nodeCellHeight() -> CGFloat {
     
        if nodeSectionLoaded {
            
            if showNodeInfo {
                
                return 205
                
            } else {
                
                return 62
                
            }
                        
        } else {
            
            return 47
            
        }
        
    }
    
    private func transactionCellHeight() -> CGFloat {
        
        if transactionsSectionLoaded {
            
            if transactionArray.count > 0 {
                
                return 80
                
            } else {
                
                return 47
                
            }
                        
        } else {
            
            return 47
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
            
        case 0:
                        
            return torCellHeight()
            
        case 1:
            
            return nodeCellHeight()
                        
        case 2:
            
            return walletCellHeight()
            
        default:
            
            return transactionCellHeight()
            
        }
        
    }
    
    @objc func switchBalances(_ sender: UILabel) {
                
        if sender.text != "" {
            
            if sender.text!.contains("$") {
                
                DispatchQueue.main.async {
                    
                    sender.text = self.coldBalance
                    
                }
                                
            } else {
                
                DispatchQueue.main.async {
                    
                    sender.text = self.fiatBalance
                    
                }
                
            }
            
        }
                    
    }
    
    private func impact() {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            
        }
        
    }
    
    @objc func getWalletInfo(_ sender: UIButton) {
        
        impact()
        
        DispatchQueue.main.async {
                        
            if self.infoHidden {
                
                self.infoHidden = false
                
            } else {
                
                self.infoHidden = true
                
            }
            
            self.reloadSections([self.walletCellIndex])
                        
        }
        
    }
    
    @objc func getTorInfo(_ sender: UIButton) {
                
        DispatchQueue.main.async {
            
            self.impact()
            
            if self.torInfoHidden {
                
                self.torInfoHidden = false
                
            } else {
                
                self.torInfoHidden = true
                
            }
            
            self.reloadSections([self.torCellIndex])
                        
        }
        
    }
    
    @objc func getNodeInfo(_ sender: UIButton) {
        
        impact()
                
        DispatchQueue.main.async {
            
            if self.showNodeInfo {
                
                self.showNodeInfo = false
                
            } else {
                
                self.showNodeInfo = true
                
            }
            
            self.reloadSections([self.nodeCellIndex])
                        
        }
        
    }
    
    private func updateWalletMetaData(wallet: WalletStruct) {
        
        if let newBalance = Double(self.walletInfo.coldBalance) {
            
            cd.updateEntity(id: wallet.id, keyToUpdate: "lastBalance", newValue: newBalance, entityName: .wallets) {}
            
        }
        
        cd.updateEntity(id: wallet.id, keyToUpdate: "lastUsed", newValue: Date(), entityName: .wallets) {}
        cd.updateEntity(id: wallet.id, keyToUpdate: "lastUpdated", newValue: Date(), entityName: .wallets) {}
        
    }
    
    private func updateLabel(text: String) {
        
        DispatchQueue.main.async {
            
            self.statusLabel.text = text
            
        }
        
    }
    
    private func loadWalletData() {
        
        self.isRefreshingZero = true
        self.reloadSections([self.walletCellIndex])
        self.updateLabel(text: "     Getting wallet info...")
        
        let nodeLogic = NodeLogic()
        nodeLogic.wallet = self.wallet
        self.existingWalletName = self.wallet.name
        nodeLogic.walletDisabled = false
        nodeLogic.loadWalletData() {
            
            if nodeLogic.errorBool {
                
                self.walletSectionLoaded = true
                self.removeStatusLabel()
                self.isRefreshingZero = false
                self.walletExists = false
                self.reloadSections([self.walletCellIndex])
                self.loadNodeData()
                displayAlert(viewController: self, isError: true, message: nodeLogic.errorDescription)
                
            } else {
                
                self.walletExists = true
                self.walletInfo = HomeStruct(dictionary: nodeLogic.dictToReturn)
                self.updateWalletMetaData(wallet: self.wallet)
                self.walletSectionLoaded = true
                self.isRefreshingZero = false
                self.reloadSections([self.walletCellIndex])
                self.impact()
                self.getDirtyFiatBalance()
                self.loadTransactionData()
                
                
            }
            
        }
        
    }
    
    private func refreshWalletData(_ sender: UIButton) {
        
        self.isRefreshingZero = true
        let nodeLogic = NodeLogic()
        nodeLogic.wallet = self.wallet
        nodeLogic.walletDisabled = false
        nodeLogic.loadWalletData() {
            
            if nodeLogic.errorBool {
                
                self.walletSectionLoaded = false
                self.removeStatusLabel()
                self.isRefreshingZero = false
                self.reloadSections([self.walletCellIndex])
                displayAlert(viewController: self, isError: true, message: nodeLogic.errorDescription)
                
            } else {
                
                self.walletInfo = HomeStruct(dictionary: nodeLogic.dictToReturn)
                self.updateWalletMetaData(wallet: self.wallet)
                self.walletSectionLoaded = true
                self.isRefreshingZero = false
                self.reloadSections([self.walletCellIndex])
                self.impact()
                self.getDirtyFiatBalance()
                
            }
            
        }
        
    }
    
    private func loadTorData() {
        
        if self.node != nil {
            
            reloadSections([self.torCellIndex])
            updateLabel(text: "     Getting Tor network data from your node...")
            let nodeLogic = NodeLogic()
            nodeLogic.loadTorData {
                
                if !nodeLogic.errorBool {
                    
                    let s = HomeStruct(dictionary: nodeLogic.dictToReturn)
                    self.p2pOnionAddress = s.p2pOnionAddress
                    self.version = s.version
                    self.torReachable = s.torReachable
                    
                    self.torSectionLoaded = true
                    self.isRefreshingTorData = false
                    
                    if self.wallet != nil {
                        
                        self.reloadSections([self.torCellIndex, self.walletCellIndex])
                        self.loadWalletData()
                        
                        
                    } else {
                        
                        self.reloadSections([self.torCellIndex, self.nodeCellIndex])
                        self.loadNodeData()
                        
                    }
                    
                } else {
                    
                    self.torSectionLoaded = false
                    self.removeStatusLabel()
                    self.isRefreshingTorData = false
                    self.reloadSections([self.torCellIndex])
                    
                    displayAlert(viewController: self,
                                 isError: true,
                                 message: nodeLogic.errorDescription)
                                        
                }
                
            }
            
        }
        
    }
    
    private func refreshTorData(_ sender: UIButton) {
        
        if self.node != nil {
            
            let nodeLogic = NodeLogic()
            nodeLogic.loadTorData {
                
                if !nodeLogic.errorBool {
                    
                    let s = HomeStruct(dictionary: nodeLogic.dictToReturn)
                    self.p2pOnionAddress = s.p2pOnionAddress
                    self.version = s.version
                    self.torReachable = s.torReachable
                    self.torSectionLoaded = true
                    self.isRefreshingTorData = false
                    self.reloadSections([self.torCellIndex])
                    
                } else {
                    
                    self.torSectionLoaded = false
                    self.removeStatusLabel()
                    self.isRefreshingTorData = false
                    self.reloadSections([self.torCellIndex])
                    
                    displayAlert(viewController: self,
                                 isError: true,
                                 message: nodeLogic.errorDescription)
                                        
                }
                
            }
            
        }
        
    }
    
    private func loadNodeData() {
        
        self.isRefreshingTwo = true
        self.reloadSections([self.nodeCellIndex])
        self.updateLabel(text: "     Getting Full Node data...")
        
        let nodeLogic = NodeLogic()
        nodeLogic.wallet = wallet
        nodeLogic.walletDisabled = walletDisabled
        nodeLogic.loadNodeData() {
            
            if nodeLogic.errorBool {
                
                self.nodeSectionLoaded = false
                self.removeStatusLabel()
                self.isRefreshingTwo = false
                self.reloadSections([self.nodeCellIndex])
                displayAlert(viewController: self, isError: true, message: nodeLogic.errorDescription)
                
            } else {
                
                let str = HomeStruct(dictionary: nodeLogic.dictToReturn)
                self.feeRate = str.feeRate
                self.mempoolCount = str.mempoolCount
                self.network = str.network
                
                if self.network == "main" {
                    
                    self.cd.updateEntity(id: self.node.id, keyToUpdate: "network", newValue: "mainnet", entityName: .nodes) {}
                    
                } else if self.network == "test" {
                    
                    self.cd.updateEntity(id: self.node.id, keyToUpdate: "network", newValue: "testnet", entityName: .nodes) {}
                    
                }
                
                self.size = str.size
                self.difficulty = str.difficulty
                self.progress = str.progress
                self.isPruned = str.pruned
                self.incomingCount = str.incomingCount
                self.outgoingCount = str.outgoingCount
                self.hashrateString = str.hashrate
                self.uptime = str.uptime
                self.currentBlock = str.blockheight
                self.nodeSectionLoaded = true
                
                self.isRefreshingTwo = false
                
                DispatchQueue.main.async {
                    
                    if self.wallet == nil {
                        
                        self.reloadSections([self.walletCellIndex, self.nodeCellIndex, 3])
                        
                    } else {
                        
                        self.reloadSections([self.nodeCellIndex])
                        
                    }
                    
                    self.impact()
                    self.removeStatusLabel()
                    
                }
                
            }
            
        }
        
    }
    
    private func refreshNodeData(_ sender: UIButton) {
        print("refreshNodeData")
        
        self.isRefreshingTwo = true
        let nodeLogic = NodeLogic()
        nodeLogic.wallet = wallet
        nodeLogic.walletDisabled = walletDisabled
        nodeLogic.loadNodeData() {
            
            if nodeLogic.errorBool {
                
                self.nodeSectionLoaded = false
                self.isRefreshingTwo = false
                self.reloadSections([self.nodeCellIndex])
                displayAlert(viewController: self, isError: true, message: nodeLogic.errorDescription)
                
            } else {
                
                let str = HomeStruct(dictionary: nodeLogic.dictToReturn)
                self.feeRate = str.feeRate
                self.mempoolCount = str.mempoolCount
                self.network = str.network
                
                if self.network == "main" {
                    
                    self.cd.updateEntity(id: self.node.id, keyToUpdate: "network", newValue: "mainnet", entityName: .nodes) {}
                    
                } else if self.network == "test" {
                    
                    self.cd.updateEntity(id: self.node.id, keyToUpdate: "network", newValue: "testnet", entityName: .nodes) {}
                    
                }
                
                self.size = str.size
                self.difficulty = str.difficulty
                self.progress = str.progress
                self.isPruned = str.pruned
                self.incomingCount = str.incomingCount
                self.outgoingCount = str.outgoingCount
                self.hashrateString = str.hashrate
                self.uptime = str.uptime
                self.currentBlock = str.blockheight
                self.nodeSectionLoaded = true
                self.isRefreshingTwo = false
                self.reloadSections([self.nodeCellIndex])
                self.impact()
                
            }
            
        }
        
    }
    
    private func loadTransactionData() {
        
        let nodeLogic = NodeLogic()
        nodeLogic.arrayToReturn.removeAll()
        updateLabel(text: "     Getting transactions...")
        nodeLogic.wallet = wallet
        nodeLogic.walletDisabled = walletDisabled
        nodeLogic.loadTransactionData() {
            
            if nodeLogic.errorBool {
                
                self.transactionsSectionLoaded = false
                self.removeStatusLabel()
                
                displayAlert(viewController: self,
                             isError: true,
                             message: nodeLogic.errorDescription)
                
            } else {
                
                DispatchQueue.main.async {
                    
                    self.transactionArray = nodeLogic.arrayToReturn.reversed()
                    self.transactionsSectionLoaded = true
                    self.impact()
                    self.mainMenu.reloadData()
                    self.loadNodeData()
                    self.sponsorThisApp()
                    
                }
                
            }
            
        }
        
    }
    
    private func refreshTransactions(_ sender: UIButton) {
        
        let nodeLogic = NodeLogic()
        nodeLogic.arrayToReturn.removeAll()
        nodeLogic.wallet = wallet
        nodeLogic.walletDisabled = walletDisabled
        nodeLogic.loadTransactionData() {
            
            if nodeLogic.errorBool {
                
                self.transactionsSectionLoaded = false
                self.removeStatusLabel()
                
                displayAlert(viewController: self,
                             isError: true,
                             message: nodeLogic.errorDescription)
                
            } else {
                
                self.transactionArray.removeAll()
                self.transactionArray = nodeLogic.arrayToReturn.reversed()
                self.transactionsSectionLoaded = true
                                
                DispatchQueue.main.async {
                    
                    self.mainMenu.reloadData()
                    self.impact()
                    
                }
                
            }
            
        }
        
    }
    
    @objc func getTransaction(_ sender: UIButton) {
        
        let index = Int(sender.restorationIdentifier!)!
        let selectedTx = self.transactionArray[index - 3]
        let txID = selectedTx["txID"] as! String
        self.tx = txID
        UIPasteboard.general.string = txID
        impact()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "getTransaction", sender: self)
            
        }
        
    }
    
    private func getDirtyFiatBalance() {
        
//        let converter = FiatConverter()
//        
//        func getResult() {
//            
//            if !converter.errorBool {
//                
//                let rate = converter.fxRate
//                
//                guard let coldDouble = Double(self.coldBalance.replacingOccurrences(of: ",", with: "")) else {
//                    
//                    return
//                    
//                }
//                
//                let formattedColdDouble = ((coldDouble * rate).rounded()).withCommas()
//                self.fiatBalance = "﹩\(formattedColdDouble) USD"
//                self.reloadSections([self.walletCellIndex])
//                
//            }
//            
//        }
//        
//        converter.getFxRate(completion: getResult)
    }
    
    //MARK: User Interface
    
    private func addStatusLabel(description: String) {
        //Matshona Dhliwayo — 'Great things take time; that is why seeds persevere through rocks and dirt to bloom.'
        
        DispatchQueue.main.async {
            
            self.mainMenu.translatesAutoresizingMaskIntoConstraints = true
            self.statusLabel.removeFromSuperview()
            self.statusLabel.frame = CGRect(x: 0, y: -50, width: self.view.frame.width, height: 50)
            self.statusLabel.backgroundColor = .black
            self.statusLabel.textAlignment = .left
            self.statusLabel.textColor = .lightGray
            self.statusLabel.font = .systemFont(ofSize: 12)
            self.statusLabel.text = description
            self.view.addSubview(self.statusLabel)
            
            UIView.animate(withDuration: 0.5, animations: {
                
                self.statusLabel.frame = CGRect(x: 16, y: self.navigationController!.navigationBar.frame.maxY + 5, width: self.view.frame.width - 32, height: 13)
                self.mainMenu.frame = CGRect(x: 0, y: self.statusLabel.frame.maxY + 15, width: self.mainMenu.frame.width, height: self.mainMenu.frame.height)
                
            })
            
        }
        
    }
    
    private func removeStatusLabel() {
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.5, animations: {
                
                if !self.sponsorShowing {
                    
                    self.statusLabel.frame.origin.y = -50
                    self.mainMenu.frame.origin.y = 40
                    self.mainMenu.translatesAutoresizingMaskIntoConstraints = false
                    
                } else {

                    self.mainMenu.frame.origin.y = self.sponsorBanner.frame.maxY

                }
                
            }) { (_) in
                
                self.statusLabel.removeFromSuperview()
                
            }
            
        }
        
    }
    
    @objc func addWallet() {

        impact()

        if self.torConnected {
            
            self.tabBarController?.selectedIndex = 1

        } else {

            showAlert(vc: self, title: "Tor not connected", message: "You need to be connected to a node over tor in order to create a wallet")

        }

    }
    
    private func configureRefresher() {
        
        refresher = UIRefreshControl()
        refresher.tintColor = UIColor.white
        refresher.attributedTitle = NSAttributedString(string: "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        refresher.addTarget(self, action: #selector(self.refreshNow), for: UIControl.Event.valueChanged)
        mainMenu.addSubview(refresher)
        
    }
    
    //MARK: User Actions
    
    @objc func closeConnectingView() {
        
        DispatchQueue.main.async {
            self.connectingView.removeConnectingView()
        }
        
    }
    
    @objc func refreshNow() {
        print("refresh")
        
        self.isRefreshingTorData = true
        self.reloadTableData()
        
    }
    
    private func addNode() {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "scanNow", sender: self)
            
        }
            
    }
    
    private func reloadTableData() {
        
        DispatchQueue.main.async {
            
            self.torSectionLoaded = false
            self.walletSectionLoaded = false
            self.transactionsSectionLoaded = false
            self.nodeSectionLoaded = false
            self.transactionArray.removeAll()
            self.refresher.endRefreshing()
            self.addStatusLabel(description: "     Connecting Tor...")
            self.mainMenu.reloadData()
            
        }
        
        getActiveWalletNow() { (w, error) in
                
            if !error {
                
                self.loadTorData()
                                
            } else {
                                
                if self.node != nil {
                    
                     self.loadTorData()
                    
                } else {
                    
                    self.isRefreshingTorData = false
                    self.removeStatusLabel()
                    displayAlert(viewController: self, isError: true, message: "no active node, please go to node manager and activate one")
                    
                }
                
            }
            
        }
        
    }
    
    private func reloadSections(_ sections: [Int]) {
        
        DispatchQueue.main.async {
            
            self.mainMenu.reloadSections(IndexSet(sections), with: .automatic)
            
        }
        
    }
    
    private func nodeJustAdded() {
        print("nodeJustAdded")
        
        self.enc.getNode { (node, error) in
            
            if !error && node != nil {
                
                self.node = node!
                self.reloadSections([self.nodeCellIndex])
                
                //if !self.torConnected {
                    
                    //TorClient.sharedInstance.start {
                        
                        self.didAppear()
                        
                    //}
                    
                //}
                
            }
            
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            
        case "settings":
            
            if let vc = segue.destination as? SettingsViewController {
                
                vc.doneBlock = { result in
                    
                    // checks if a different node was activated when user went to settings and refreshes the table if they did
                    self.enc.getNode { (node, error) in
                        
                        if !error && node != nil {
                            
                            if node!.id != self.existingNodeId {
                                
                                self.didAppear()
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        case "goToWallets":
            
            if let vc = segue.destination as? WalletsViewController {
                
                vc.node = self.node
                
            }
            
        case "getTransaction":
            
            if let vc = segue.destination as? TransactionViewController {
                
                vc.txid = tx
                
            }
            
        case "scanNow":
            
            if let vc = segue.destination as? ScannerViewController {
                
                vc.scanningNode = true
                
                vc.onDoneBlock = { result in
                    
                    self.nodeJustAdded()
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }
    
    //MARK: Helpers
    
    private func firstTimeHere() {
        
        setFeeTarget()
        
        let firstTime = FirstTime()
        firstTime.firstTimeHere { (success) in
            
            if success {
                
                //self.showUnlockScreen()
                
            } else {
                
                displayAlert(viewController: self, isError: true, message: "Something very wrong has happened... Please delete the app and try again.")
                
            }
            
        }
        
    }
    
    private func sponsorThisApp() {
        
        sponsorShowing = true
        
        DispatchQueue.main.async {
            
            self.mainMenu.translatesAutoresizingMaskIntoConstraints = true
            
            self.background.frame = CGRect(x: 0, y: self.navigationController!.view.frame.minY - 50, width: self.view.frame.width, height: 50)
            
            self.sponsorBanner.backgroundColor = .clear
            self.sponsorBanner.frame = CGRect(x: 0, y: self.navigationController!.view.frame.minY - 50, width: self.view.frame.width, height: 50)
            let sponsorImage = UIImage(systemName: "heart")
            self.sponsorBanner.setTitle(" Sponsor Blockchain Commons!", for: .normal)
            self.sponsorBanner.setImage(sponsorImage, for: .normal)
            self.sponsorBanner.tintColor = .systemPink
            self.sponsorBanner.titleLabel?.font = .systemFont(ofSize: 15)
            self.sponsorBanner.addTarget(self, action: #selector(self.sponsorNow), for: .touchUpInside)
            self.sponsorBanner.setTitleColor(.white, for: .normal)
            
            self.closeButton.frame = CGRect(x: self.navigationController!.view.frame.maxX - 50, y: self.navigationController!.view.frame.minY - 50, width: 20, height: 20)
            self.closeButton.addTarget(self, action: #selector(self.closeSponsorButton), for: .touchUpInside)
            let closeImage = UIImage(systemName: "x.circle")!
            self.closeButton.setImage(closeImage, for: .normal)
            self.closeButton.tintColor = .white
            self.closeButton.backgroundColor = .clear
            
            self.view.addSubview(self.background)
            self.view.addSubview(self.sponsorBanner)
            self.view.addSubview(self.closeButton)
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.mainMenu.frame.origin.y +=  50
                self.statusLabel.frame.origin.y += 50
                self.background.frame = CGRect(x: 0, y: self.navigationController!.navigationBar.frame.maxY, width: self.view.frame.width, height: 50)
                self.sponsorBanner.frame = CGRect(x: 0, y: self.navigationController!.navigationBar.frame.maxY, width: self.view.frame.width, height: 50)
                self.closeButton.frame = CGRect(x: self.sponsorBanner.frame.maxX - 50, y: self.navigationController!.navigationBar.frame.maxY + 15, width: 20, height: 20)
                
            }) { (_) in
                                
                DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                    
                    if self.sponsorShowing {
                        
                        self.mainMenu.translatesAutoresizingMaskIntoConstraints = false
                        
                        UIView.animate(withDuration: 0.3, animations: {
                            
                            self.background.frame = CGRect(x: 0, y: self.navigationController!.view.frame.minY - 50, width: self.view.frame.width, height: 50)
                            self.sponsorBanner.frame = CGRect(x: 0, y: self.navigationController!.view.frame.minY - 50, width: self.view.frame.width, height: 50)
                            self.closeButton.frame = CGRect(x: self.sponsorBanner.frame.maxX - 25, y: self.navigationController!.view.frame.minY - 50, width: 20, height: 20)
                            self.mainMenu.frame.origin.y -= 50
                            self.statusLabel.frame.origin.y -= 50
                            
                        }) { (_) in
                            
                            self.sponsorBanner.removeFromSuperview()
                            self.background.removeFromSuperview()
                            self.closeButton.removeFromSuperview()
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    @objc func closeSponsorButton() {
        
        sponsorShowing = false
        
        DispatchQueue.main.async {
            
            self.mainMenu.translatesAutoresizingMaskIntoConstraints = false
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.background.frame = CGRect(x: 0, y: self.navigationController!.view.frame.minY - 50, width: self.view.frame.width, height: 50)
                self.sponsorBanner.frame = CGRect(x: 0, y: self.navigationController!.view.frame.minY - 50, width: self.view.frame.width, height: 50)
                self.closeButton.frame = CGRect(x: self.sponsorBanner.frame.maxX - 25, y: self.navigationController!.view.frame.minY - 50, width: 20, height: 20)
                self.mainMenu.frame.origin.y -= 50
                self.statusLabel.frame.origin.y -= 50
                
            }) { (_) in
                
                self.sponsorBanner.removeFromSuperview()
                self.background.removeFromSuperview()
                self.closeButton.removeFromSuperview()
                
            }
            
        }
        
    }
    
    @objc func sponsorNow() {
        
        impact()
        UIApplication.shared.open(URL(string: "https://github.com/sponsors/BlockchainCommons")!) { (Bool) in }
        
    }
    
    private func reducedName(name: String) -> String {
        
        let first = String(name.prefix(5))
        let last = String(name.suffix(5))
        return "\(first)*****\(last).dat"
        
    }
    
}

extension Double {
    
    func withCommas() -> String {
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        return numberFormatter.string(from: NSNumber(value:self))!
        
    }
    
}
