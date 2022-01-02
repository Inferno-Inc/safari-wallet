//
//  TransactionViewModel.swift
//  Wallet
//
//  Created by Stefano on 01.01.22.
//

import BigInt
import Foundation
import MEWwalletKit

struct TransactionViewModel: Identifiable {
    var id: UUID
    let hash: String
    let fromAddress: String
    let toAddress: String?
    let token: String?
    let fiat: String?
    let type: TransactionType
}

// MARK: - Domain to View Model Mapping

extension TransactionViewModel {
    
    init(tx: TransactionActivity) {
        let token = TransactionViewModel.mapToToken(tx: tx)
        let currency = TransactionViewModel.mapToCurrency(tx: tx)
        let from = TransactionViewModel.mapToTruncatedAddress(tx.from)
        let to = tx.to.flatMap(TransactionViewModel.mapToTruncatedAddress)
        self.init(
            id: UUID(),
            hash: tx.txHash,
            fromAddress: from,
            toAddress: to,
            token: token,
            fiat: currency,
            type: tx.type
        )
    }
    
    static func mapToTruncatedAddress(_ address: Address) -> String {
        let address = address.address.lowercased()
        return address.prefix(5) + "..." + address.suffix(5)
    }
    
    static func mapToToken(tx: TransactionActivity) -> String? {
        switch tx.type {
        case .send: // stake, deployment, deposit, repay ?
            guard let asset = tx.assets.out else { return nil }
            return mapToToken(asset: asset)
        default:
            guard let asset = tx.assets.in else { return nil }
            return mapToToken(asset: asset)
        }
    }
    
    static func mapToToken(asset: Asset) -> String? {
        switch asset {
        case .native(let asset):
            let value = asset.value.convert(withDecimals: asset.decimal).rounded(toPlaces: 4)
            let symbol = asset .symbol
            return "\(value) \(symbol)"
        case .erc20(let asset):
            let value = asset.value.convert(withDecimals: asset.decimal).rounded(toPlaces: 4)
            let symbol = asset .symbol
            return "\(value) \(symbol)"
        }
    }
    
    static func mapToCurrency(tx: TransactionActivity) -> String? {
        switch tx.type {
        case .send: // stake, deployment, deposit, repay
            guard let asset = tx.assets.out else { return nil }
            return mapToCurrency(asset: asset)
        default:
            // check for ens registrations (type trade)
            guard let asset = tx.assets.in else { return nil }
            return mapToCurrency(asset: asset)
        }
    }
    
    static func mapToCurrency(asset: Asset) -> String? {
        switch asset {
        case .native(let asset):
            // TODO: do proper currency formatting
            // Should we use current prices or prices at time of tx?
            guard let price = asset.currentPrice else { return nil }
            let value = (asset.value.convert(withDecimals: asset.decimal) * price.value).rounded(toPlaces: 2)
            let symbol = price.currency
            return "\(value) \(symbol)"
        case .erc20(let asset):
            guard let price = asset.currentPrice else { return nil }
            let value = (asset.value.convert(withDecimals: asset.decimal) * price.value).rounded(toPlaces: 2)
            let symbol = price.currency
            return "\(value) \(symbol)"
        }
    }
}

// TODO: Move to extensions folder

extension BigInt {
    
    func convert(withDecimals decimals: Int) -> Double {
        if decimals == 0 { return Double(self) }
        return Double(self) / pow(Double(10),Double(decimals))
    }
}

extension Double {

    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
