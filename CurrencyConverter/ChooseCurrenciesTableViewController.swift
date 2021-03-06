//
//  ChooseCurrenciesTableViewController.swift
//  CurrencyConverter
//
//  Created by Jhantelle Belleza on 6/7/17.
//  Copyright © 2017 JhantelleB. All rights reserved.
//

import UIKit
import SwiftSpinner

protocol ChosenCurrencyDelegate: class {
    func passChosen(_ currencies: [String])
}

class ChooseCurrenciesTableViewController: UITableViewController {
    
    let store = CurrencyDataStore.sharedInstance
    var chooseCurrency: [ChooseCurrencyItem] = []
    var selectedCurrencies: Set<String> = []
    let currencyFlagsAndSigns = CurrencyFlagAndSignsDictionary()
    
    //Search Bar Controller
    var searchedCurrencies = [ChooseCurrencyItem]()
    let searchController = UISearchController(searchResultsController: nil)
    
    //Localized Index
    let collation = UILocalizedIndexedCollation.current()
    var chooseCurrencyWithSections = [[ChooseCurrencyItem]]()
    var sectionTitles = [String]()
    
    weak var delegate: ChosenCurrencyDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SwiftSpinner.show("Loading available currencies", animated: true)
        DispatchQueue.main.async {
            self.store.getListOfAvailableCurrencies{ data in
                let filtered = self.filterDisplay(data)
                self.chooseCurrency = self.checkDisplayed(filtered).sorted{ $0.base < $1.base }
                
                // Localized Index
                let (arrayChoose, arrayTitles) = self.collation.partitionObjects(self.chooseCurrency as [ChooseCurrencyItem], collationStringSelector:
                    #selector(getter: ChooseCurrencyItem.countryName))
                self.chooseCurrencyWithSections = arrayChoose as! [[ChooseCurrencyItem]]
                self.sectionTitles = arrayTitles
                self.tableView.reloadData()
                SwiftSpinner.hide()
            }
            
        }
        
        //Search Control Bar setup
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.clipsToBounds = true
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        
        tableView.delegate = self
        tableView.tableHeaderView = searchController.searchBar
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //IB Actions
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func chooseButtonPressed(_ sender: Any) {
        let chosenCurrencies: [String] = Array(selectedCurrencies)
        self.dismiss(animated: true) {
            self.delegate?.passChosen(chosenCurrencies)
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive &&
            searchController.searchBar.text != ""  {
            return 1
        }
        return chooseCurrencyWithSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive &&
            searchController.searchBar.text != "" {
            return searchedCurrencies.count
        }
        return chooseCurrencyWithSections[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chooseCell", for: indexPath)
        cell.tintColor = UIColor.orange
        
        
        if searchController.isActive &&
            !(searchController.searchBar.text?.isEmpty)! {
            let choose = searchedCurrencies[indexPath.row]
            cell.textLabel?.text = choose.countryName
            cell.detailTextLabel?.text = choose.base
            if searchedCurrencies[indexPath.row].selected {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else {
            let choose = chooseCurrencyWithSections[indexPath.section][indexPath.row]
            cell.textLabel?.text = choose.countryName
            cell.detailTextLabel?.text = choose.base
            if choose.selected {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        //        var item = chooseCurrencyWithSections[indexPath.section][indexPath.row]
        
        let item = searchController.isActive && searchController.searchBar.text != "" ? searchedCurrencies[indexPath.row] : chooseCurrencyWithSections[indexPath.section][indexPath.row]
        
        
        //MARK: Refactored if else from v 1.0.3
        if searchController.isActive &&
           searchController.searchBar.text != "" { //when using search bar, leave selection to blank first
            searchedCurrencies[indexPath.row].selected = !item.selected
        } else { //Tapping current row, choosing current row
            chooseCurrency[indexPath.row].selected = !item.selected
            item.selected = !item.selected
        }
        
        if let cell = tableView.cellForRow(at: indexPath) {
            if item.selected {
                if self.selectedCurrencies.count < 9 {
                    selectedCurrencies.insert(item.base)
                    cell.accessoryType = .checkmark
                } else {
                    let alert = UIAlertController(title: "Currency Overload!", message: "You can only pick 10 currencies at a time. \n (Including the base currency)", preferredStyle: .actionSheet)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                selectedCurrencies.remove(item.base)
                cell.accessoryType = .none
                if self.selectedCurrencies.count > 9 {
                    let alert = UIAlertController(title: "Currency Overload!", message: "You can only pick 10 currencies at a time. \n (Including the base currency)", preferredStyle: .actionSheet)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    //Localized Index
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive &&
            searchController.searchBar.text != ""  {
            return ""
        }
        return collation.sectionTitles[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return collation.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    //Helper functions
    fileprivate func checkDisplayed(_ currencies: [ChooseCurrencyItem]) -> [ChooseCurrencyItem] {
        var updated = currencies
        
        for (index, currency) in updated.enumerated() {
            //selected currencies
            self.selectedCurrencies.forEach{
                if $0 == currency.base {
                    updated[index].selected = true
                }
            }
        }
        return updated
    }
    
    
    fileprivate func filterDisplay(_ currencies: [ChooseCurrencyItem]) -> [ChooseCurrencyItem] {
        
        let currencyDisplay = self.currencyFlagsAndSigns.listOfAvailableCurrencies
        var currencyReturn: [ChooseCurrencyItem] = []
        
        currencyDisplay.forEach { display in
            let _ = currencies.filter{
                if $0.base.lowercased() == display.key {
                    let displayValue = display.value as! CurrencyFlagandSign
                    let currencyItem = ChooseCurrencyItem(base: display.key)
                    currencyItem.currencyName = displayValue.currencyName
                    currencyItem.countryName = $0.countryName
                    currencyItem.flagImage = UIImage(named: displayValue.flagImageName)
                    currencyItem.selected = $0.selected
                    currencyItem.base = currencyItem.base.uppercased()
                    currencyReturn.append(currencyItem)
                }
                return true
            }
        }
        return currencyReturn
    }
    
    //MARK: Search controller helper functions
    fileprivate func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        searchedCurrencies = self.chooseCurrency.filter{ currency -> Bool in
            
            guard let countryName = currency.countryName else { return false }
            let base = currency.base
            return base.lowercased().contains(searchText.lowercased()) ||
                countryName.lowercased().contains(searchText.lowercased())
        }
        self.tableView.reloadData()
    }
}

//UI Search Controller extensions
extension ChooseCurrenciesTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    //Scope
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

//Localized Indexed Collation -
//from http://www.yudiz.com/creating-tableview-with-section-indexes/
extension UILocalizedIndexedCollation {
    //func for partition array in sections
    func partitionObjects(_ array: [ChooseCurrencyItem], collationStringSelector: Selector) -> ([AnyObject], [String]) {
        
        var unsortedSections = [[AnyObject]]()
        //1. Create a array to hold the data for each section
        for _ in self.sectionTitles {
            unsortedSections.append([]) //appending an empty array
        }
        //2. put each objects into a section
        for item in array {
            let index:Int = self.section(for: item, collationStringSelector:collationStringSelector)
            unsortedSections[index].append(item)
        }
        //3. sort the array of each sections
        var sections = [AnyObject]()
        var sectionTitles = [String]()
        for index in 0 ..< unsortedSections.count {
            if unsortedSections.count > 0 { //if section has entries
                sectionTitles.append(self.sectionTitles[index])
                sections.append(self.sortedArray(from: unsortedSections[index], collationStringSelector: collationStringSelector) as AnyObject)
            }
        }
        return (sections, sectionTitles)
    }
}
