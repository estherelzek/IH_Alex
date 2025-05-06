//
//  BookSearchResultViewController.swift
//  IH_Alex
//
//  Created by Esther Elzek on 05/05/2025.
//

import UIKit

struct SearchResult {
    let chapterNumber: Int
    let chapterName: String
    let pageNumber: Int
    let content: String
}

protocol BookSearchDelegate: AnyObject {
    func didSelectSearchResult(_ result: SearchResult)
}

class BookSearchResultViewController: UIViewController, UISearchBarDelegate  {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var pageController: PagedTextViewController?
    var pages: [PageContent] = [] // Pass this from MainVC
    var metadata: MetaDataResponse? // Also passed
    var results: [SearchResult] = []
    weak var delegate: BookSearchDelegate? // Notify MainVC
    var resultsByChapter: [Int: [SearchResult]] = [:]
    var sortedChapters: [Int] = [] // For ordered section access

    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
            tableView.layer.cornerRadius = 16
            tableView.clipsToBounds = true
            tableView.separatorStyle = .none
            tableView.delegate = self
            tableView.dataSource = self
         tableView.register(UINib(nibName: "BookSearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: "BookSearchResultCell")
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismissSelf()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        guard let keyword = searchBar.text?.lowercased(), !keyword.isEmpty else { return }

        results = []

        // Create a lookup table from chapter number to name
        var chapterNameMap: [Int: String] = [:]
        if let indexList = metadata?.decodedIndex() {
            for item in indexList {
                chapterNameMap[item.number] = item.name
            }
        }

        for page in pages {
            let text = page.attributedText.string.lowercased()
            if text.contains(keyword) {
                let matches = text.ranges(of: keyword)
                for range in matches {
                    let snippet = text.snippet(around: range, radius: 40)
                    let chapterNumber = page.chapterNumber
                    let chapterName = chapterNameMap[chapterNumber] ?? "Chapter \(chapterNumber)"

                    results.append(SearchResult(
                        chapterNumber: chapterNumber,
                        chapterName: chapterName,
                        pageNumber: page.pageNumberInBook,
                        content: snippet
                    ))
                }
            }
        }

        groupResultsByChapter()
        tableView.reloadData()
    }

    
    func groupResultsByChapter() {
        resultsByChapter = Dictionary(grouping: results, by: { $0.chapterNumber })
        sortedChapters = resultsByChapter.keys.sorted()
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
            cell.chapterNumberLabel.text = "Chapter \(result.chapterNumber)"
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

        // ✅ Find real page index (safe navigation)
        if let realPageIndex = pages.firstIndex(where: {
            $0.chapterNumber == result.chapterNumber &&
            $0.pageNumberInBook == result.pageNumber
        }) {
            print("Navigating to realPageIndex: \(realPageIndex)")

            pageController.currentIndex = realPageIndex
           // self.pageIndex = realPageIndex

            if let targetVC = pageController.getViewController(at: realPageIndex) {
                pageController.pageViewController.setViewControllers(
                    [targetVC],
                    direction: .forward,
                    animated: false,
                    completion: { finished in
                        print("✅ Navigated to selected search result.")
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
                // Text was cleared with the delete button
                // Reload the table with default or empty results
                clearSearchResultsAndReload()
            }
        }
    func clearSearchResultsAndReload() {
        results = []
        resultsByChapter = [:]
        sortedChapters = []
        tableView.reloadData()
    }

}
