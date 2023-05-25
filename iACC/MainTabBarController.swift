//	
// Copyright © Essential Developer. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
	
    private var friendsCache : FriendsCache!
    
    convenience init(friendsCache : FriendsCache) {
		self.init(nibName: nil, bundle: nil)
        self.friendsCache = friendsCache
		self.setupViewController()
	}

	private func setupViewController() {
		viewControllers = [
			makeNav(for: makeFriendsList(), title: "Friends", icon: "person.2.fill"),
			makeTransfersList(),
			makeNav(for: makeCardsList(), title: "Cards", icon: "creditcard.fill")
		]
	}
	
	private func makeNav(for vc: UIViewController, title: String, icon: String) -> UIViewController {
		vc.navigationItem.largeTitleDisplayMode = .always
		
		let nav = UINavigationController(rootViewController: vc)
		nav.tabBarItem.image = UIImage(
			systemName: icon,
			withConfiguration: UIImage.SymbolConfiguration(scale: .large)
		)
		nav.tabBarItem.title = title
		nav.navigationBar.prefersLargeTitles = true
		return nav
	}
	
	private func makeTransfersList() -> UIViewController {
		let sent = makeSentTransfersList()
		sent.navigationItem.title = "Sent"
		sent.navigationItem.largeTitleDisplayMode = .always
		
		let received = makeReceivedTransfersList()
		received.navigationItem.title = "Received"
		received.navigationItem.largeTitleDisplayMode = .always
		
		let vc = SegmentNavigationViewController(first: sent, second: received)
		vc.tabBarItem.image = UIImage(
			systemName: "arrow.left.arrow.right",
			withConfiguration: UIImage.SymbolConfiguration(scale: .large)
		)
		vc.title = "Transfers"
		vc.navigationBar.prefersLargeTitles = true
		return vc
	}
	
    private func makeFriendsList() -> ListViewController {
        let isPremium = User.shared?.isPremium == true
        let vc = ListViewController()
        vc.fromFriendsScreen = true
        vc.shouldRetry = true
        vc.maxRetryCount = 2
        vc.title = "Friends"
        
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: vc, action: #selector(vc.addFriend))
        vc.service = FriendsAPIItemsServiceAdapter(api: FriendsAPI.shared
                                                   , cache: isPremium ? friendsCache : NullFriendCache(), select: { [weak vc] item in
            vc?.select(friend: item)
        })
        return vc
    }
	
	private func makeSentTransfersList() -> ListViewController {
		let vc = ListViewController()
		vc.fromSentTransfersScreen = true
        vc.shouldRetry = true
        vc.maxRetryCount = 1
        vc.longDateStyle = true

        vc.navigationItem.title = "Sent"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: vc, action: #selector(vc.sendMoney))
        
        vc.service = TransfersAPIItemsServiceAdapter(api: TransfersAPI.shared, fromSentTransfersScreen: true, select: { [weak vc] item in
            vc?.select(transfer: item)
        })
		return vc
	}
	
	private func makeReceivedTransfersList() -> ListViewController {
		let vc = ListViewController()
		vc.fromReceivedTransfersScreen = true
        vc.shouldRetry = true
        vc.maxRetryCount = 1
        vc.longDateStyle = false
        
        vc.navigationItem.title = "Received"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Request", style: .done, target: vc, action: #selector(vc.requestMoney))
        vc.service = TransfersAPIItemsServiceAdapter(api: TransfersAPI.shared, fromSentTransfersScreen: false, select: { [weak vc] item in
            vc?.select(transfer: item)
        })
		return vc
	}
	
	private func makeCardsList() -> ListViewController {
		let vc = ListViewController()
        vc.shouldRetry = false
        
        vc.title = "Cards"
        
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: vc, action: #selector(vc.addCard))
		vc.fromCardsScreen = true
        vc.service = CardsAPIItemsServiceAdapter(api: CardAPI.shared, select: { [weak vc] item in
            vc?.select(card: item)
        })
		return vc
	}
	
}
struct FriendsAPIItemsServiceAdapter : APIService{
    let api : FriendsAPI
    let cache : FriendsCache
    var select : (Friend)->Void
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        api.loadFriends {  result in
            DispatchQueue.mainAsyncIfNeeded {
                completion(result.map{ items in
                        cache.save(items )
                    return items.map{item in
                         ItemViewModel(friend: item) {
                            select(item)
                        }
                    }
                })
            }
        }
    }
}
struct CardsAPIItemsServiceAdapter : APIService{
    let api : CardAPI
    var select : (Card)->Void
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        api.loadCards { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion(result.map{ items in
                    items.map{item in
                        ItemViewModel(card: item) {
                            select( item)
                        }
                    }
                })
            }
        }
    }
}
struct TransfersAPIItemsServiceAdapter : APIService{
    let api : TransfersAPI
    let fromSentTransfersScreen : Bool
    var select : (Transfer)->Void
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        api.loadTransfers { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion(result.map{items in
                    let filteredItems = fromSentTransfersScreen ? items.filter(\.isSender) : items.filter { !$0.isSender }
                    //                        var filteredItems = items.filter{
                    //                            fromSentTransfersScreen ? $0.isSender : !$0.isSender
                    //                        }
                    return filteredItems.map{ item in
                        ItemViewModel(transfer: item, longDateStyle: fromSentTransfersScreen) {
                            select(item)
                        }
                    }
                })
            }
        }
    }
}


class NullFriendCache : FriendsCache {
    override func save(_ newFriends: [Friend]) {    }
}
