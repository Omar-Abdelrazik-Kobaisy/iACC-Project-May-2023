//
// Copyright © Essential Developer. All rights reserved.
//

import UIKit

protocol APIService {
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void)
}



class ListViewController: UITableViewController {
	var items = [ItemViewModel]()
    var service : APIService?
	var retryCount = 0
	var maxRetryCount = 0
	var shouldRetry = false
	
	var longDateStyle = false
	
	var fromReceivedTransfersScreen = false
	var fromSentTransfersScreen = false
	var fromCardsScreen = false
	var fromFriendsScreen = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if tableView.numberOfRows(inSection: 0) == 0 {
			refresh()
		}
	}
	
	@objc private func refresh() {
		refreshControl?.beginRefreshing()
            service?.loadItems(completion: handleAPIResult)
	}
	
	private func handleAPIResult(_ result: Result<[ItemViewModel], Error>) {
		switch result {
		case let .success(items):
//			self.retryCount = 0
            self.items = items
			self.refreshControl?.endRefreshing()
			self.tableView.reloadData()
			
		case let .failure(error):
			    self.show(error: error)
				self.refreshControl?.endRefreshing()
			}
		}
	
    func show(error : Error){
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.showDetailViewController(alert, sender: self)
    }
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		items.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let item = items[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "ItemCell")
        
        
		cell.configure(item)
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item = items[indexPath.row]
        item.select()
	}
    func select(friend : Friend){
        let vc = FriendDetailsViewController()
        vc.friend = friend
        show(vc, sender: self)
    }
    func select(card : Card){
        let vc = CardDetailsViewController()
        vc.card = card
        show(vc, sender: self)  
    }
    func select(transfer : Transfer){
        let vc = TransferDetailsViewController()
        vc.transfer = transfer
        show(vc, sender: self)
    }
	@objc func addCard() {
		show(AddCardViewController(), sender: self)
	}
	
	@objc func addFriend() {
        show(AddFriendViewController(), sender: self)
	}
	
	@objc func sendMoney() {
        show(SendMoneyViewController(), sender: self)
	}
	
    @objc func requestMoney() { 
        show(RequestMoneyViewController(),sender: self )
	}
}

struct ItemViewModel {
    let title : String
    let subTitle : String
    let select : () -> Void
    
    init(friend : Friend , selection : @escaping () ->Void )
    {
        title = friend.name
        subTitle = friend.phone
        select = selection
    }
    init(card : Card , selection : @escaping () ->Void)
    {
        title = card.number
        subTitle = card.holder
        select = selection
    }
    init(transfer : Transfer , longDateStyle :Bool , selection : @escaping () ->Void )
    {
        let numberFormatter = Formatters.number
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = transfer.currencyCode
        
        let amount = numberFormatter.string(from: transfer.amount as NSNumber)!
        title = "\(amount) • \(transfer.description)"
        
        let dateFormatter = Formatters.date
        if longDateStyle {
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            subTitle = "Sent to: \(transfer.recipient) on \(dateFormatter.string(from: transfer.date))"
        } else {
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            subTitle = "Received from: \(transfer.sender) on \(dateFormatter.string(from: transfer.date))"
        }
        select = selection
    }
    
}

extension UITableViewCell {
    
    func configure(_ vm: ItemViewModel) {
        textLabel?.text = vm.title
        detailTextLabel?.text = vm.subTitle
    }
}
