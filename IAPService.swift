//
//  IAPService.swift
//  Smart Camera
//
//  Created by Aditya Goel on 12/09/2018.
//  Copyright © 2018 Aditya Goel. All rights reserved.
//

import Foundation
import StoreKit

class IAPService: NSObject {
    private override init() {}
    static let shared = IAPService()
    var products = [SKProduct]()
    let paymentQueue = SKPaymentQueue.default()
    
    func getProducts() {
        let products:Set = [IAPProduct.nonConsumable.rawValue]
        let request = SKProductsRequest(productIdentifiers: products)
        request.delegate = self
        request.start()
        paymentQueue.add(self)
    }
    
    func purchase(product: IAPProduct) {
        guard let productToPurchase = products.filter({ $0.productIdentifier == product.rawValue}).first else { return }
        let payment = SKPayment(product: productToPurchase)
        paymentQueue.add(payment)
    }
    
    func restorePurchases() {
        print("restoring purchases")
        paymentQueue.restoreCompletedTransactions()
        //print("££££!!!")
    }
    
    func purchasePass() {
        UserDefaults.standard.set(true, forKey: "Unlimited")
        print("££££!!!")
    }
}

extension IAPService:SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        for product in response.products {
            //print("JJJ")
            //print(product.localizedTitle)
        }
    }
}

extension IAPService: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            //print(transaction.transactionState.status(), transaction.payment.productIdentifier)
            switch transaction.transactionState {
            case .purchasing: break
            case .purchased : purchasePass()
            case .restored : purchasePass()
            default: queue.finishTransaction(transaction)
            }
        }
    }
}


extension SKPaymentTransactionState {
    func status() -> String {
        switch self {
        case .deferred: return "deferred"
        case .failed: return "failed"
        case .purchased: return "purchasing"
        case .purchasing: return "purchasing"
        case .restored: return "restored"
        }
    }
}
