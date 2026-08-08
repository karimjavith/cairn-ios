//
//  AccountRepository.swift
//  Cairn
//
//  Created by Karim Sheikh on 08/08/2026.
//

protocol AccountRepository: Sendable {
    func fetchAccounts() async throws -> [Account]
    func fetchAccount(id: AccountID) async throws -> Account?
    func save(_ account: Account) async throws
    func deleteAccount(id: AccountID) async throws
}
