//
//  BookSearchResultViewController.swift
//  IH_Alex
//
//  Created by Esther Elzek on 05/05/2025.
//

import UIKit
import Foundation

struct SearchResult: Codable {
    let chapterNumber: Int
    let chapterName: String
    let pageNumber: Int
    let content: String
    let globalRange: NSRange
}

extension NSRange: Codable {
    enum CodingKeys: String, CodingKey {
        case location
        case length
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(location, forKey: .location)
        try container.encode(length, forKey: .length)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let location = try container.decode(Int.self, forKey: .location)
        let length = try container.decode(Int.self, forKey: .length)
        self.init(location: location, length: length)
    }
}

protocol BookSearchDelegate: AnyObject {
    func didSelectSearchResult(_ result: SearchResult)
}

class BookSearchResultViewController: UIViewController, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var emptySearchimage: UIImageView!
    
    var pageController: PagedTextViewController?
    var pages: [Chunk] = []
    var metadata: MetaDataResponse?
    var results: [SearchResult] = []
    weak var delegate: BookSearchDelegate?
    var resultsByChapter: [Int: [SearchResult]] = [:]
    var sortedChapters: [Int] = []
    weak var internalLinkDelegate: InternalLinkNavigationDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "BookSearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: "BookSearchResultCell")

        // 👉 Load previously saved search results and keyword
        let (savedResults, savedKeyword) = SearchResultManager.shared.loadSearchResults()
        
        if !savedResults.isEmpty, let keyword = savedKeyword {
            results = savedResults
            searchBar.text = keyword
            groupResultsByChapter()
            emptySearchimage.isHidden = !results.isEmpty
            tableView.isHidden = results.isEmpty
            tableView.reloadData()
        }
    }

    
    @IBAction func backButton(_ sender: Any) {
        dismissSelf()
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false

        let keyword = searchBar.text?.lowercased()
        results = []
        
        var chapterNameMap: [Int: String] = [:]
        if let indexList = metadata?.decodedIndex() {
            for item in indexList {
                chapterNameMap[item.number] = item.name
            }
        }

        for page in pages {
            let text = page.attributedText.string.lowercased()
            if text.contains(keyword ?? "") {
                let matches = text.ranges(of: keyword ?? "")
                for range in matches {
                    let snippet = text.snippet(around: range, radius: 10)
                    let chapterNumber = page.chapterNumber
                    let chapterName = chapterNameMap[chapterNumber] ?? "Chapter \(chapterNumber)"
                    
                    let searchResult = SearchResult(
                        chapterNumber: chapterNumber,
                        chapterName: chapterName,
                        pageNumber: page.pageNumberInBook,
                        content: snippet,
                        globalRange: NSRange(range, in: text)
                    )
                    results.append(searchResult)
                }
            }
        }

        // 👉 Save the search results and keyword
        SearchResultManager.shared.saveSearchResults(results, keyword: keyword)
        
        groupResultsByChapter()
        emptySearchimage.isHidden = !results.isEmpty
        tableView.isHidden = results.isEmpty
        tableView.reloadData()
    }


    func groupResultsByChapter() {
        resultsByChapter = Dictionary(grouping: results, by: { $0.chapterNumber })
        sortedChapters = resultsByChapter.keys.sorted()
    }
    
    func clearSearchResultsAndReload() {
        results = []
        resultsByChapter = [:]
        sortedChapters = []
        emptySearchimage.isHidden = false
        tableView.isHidden = true
        SearchResultManager.shared.clearAllSearchResults()
    }

}

// MARK: - UITableView Data Source & Delegate
extension BookSearchResultViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedChapters.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let chapter = sortedChapters[section]
        return resultsByChapter[chapter]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let chapter = sortedChapters[section]
        if let result = resultsByChapter[chapter]?.first {
            return "Chapter \(result.chapterNumber):   \(result.chapterName)"
        }
        return "Chapter \(chapter)"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BookSearchResultCell", for: indexPath) as? BookSearchResultTableViewCell else {
            fatalError("Could not dequeue BookSearchResultTableViewCell")
        }

        let chapter = sortedChapters[indexPath.section]
        if let result = resultsByChapter[chapter]?[indexPath.row] {
        //    cell.chapterNumberLabel.text = "Chapter \(result.chapterNumber)"
            cell.pageNumberLabel.text = "Page \(result.pageNumber)"
            cell.contentSearchLabel.text = result.content
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chapter = sortedChapters[indexPath.section]
        guard let result = resultsByChapter[chapter]?[indexPath.row],
              let pageController = self.pageController else {
          
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        if let realPageIndex = pages.firstIndex(where: {
            $0.chapterNumber == result.chapterNumber &&
            $0.pageNumberInBook == result.pageNumber
        }) {
            pageController.currentIndex = realPageIndex
            internalLinkDelegate?.didNavigateToInternalLink(pageIndex: realPageIndex)
            if let targetVC = pageController.getViewController(at: realPageIndex) {
                let resultsInSamePage = results.filter {
                    $0.pageNumber == result.pageNumber && $0.chapterNumber == result.chapterNumber
                }
                targetVC.searchResults = resultsInSamePage
                pageController.pageViewController?.setViewControllers(
                    [targetVC],
                    direction: .forward,
                    animated: false,
                    completion: { [weak self] finished in
                        print("✅ Navigated to selected search result.")
                        targetVC.highlightSearchResults()
                    }
                )
            }
            pageController.pageControl.currentPage = realPageIndex
        } else {
            print("❌ Could not find matching page in current list.")
        }


        tableView.deselectRow(at: indexPath, animated: true)
        self.dismissSelf()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80 // or any fixed height you prefer
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            clearSearchResultsAndReload()
        }
    }
}
