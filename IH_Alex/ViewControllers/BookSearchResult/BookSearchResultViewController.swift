//
//  BookSearchResultViewController.swift
//  IH_Alex
//
//  Created by Esther Elzek on 05/05/2025.
//

import UIKit

struct SearchResult {
    let chapterNumber: Int
    let pageNumber: Int
    let content: String
}

import UIKit

class BookSearchResultViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var results: [SearchResult] = [
        SearchResult(chapterNumber: 1, pageNumber: 3, content: "This is a sample result."),
        SearchResult(chapterNumber: 2, pageNumber: 12, content: "Another matching result."),
        SearchResult(chapterNumber: 2, pageNumber: 12, content: "Another matching result."),
        SearchResult(chapterNumber: 1, pageNumber: 3, content: "This is a sample result."),
        SearchResult(chapterNumber: 2, pageNumber: 12, content: "Another matching result."),
        SearchResult(chapterNumber: 3, pageNumber: 20, content: "A third example entry.")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            tableView.layer.cornerRadius = 16
            tableView.clipsToBounds = true
            tableView.separatorStyle = .none
            tableView.delegate = self
            tableView.dataSource = self
         tableView.register(UINib(nibName: "BookSearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: "BookSearchResultCell")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
           tapGesture.cancelsTouchesInView = false
           view.addGestureRecognizer(tapGesture)
    }
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableView Data Source & Delegate
extension BookSearchResultViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BookSearchResultCell", for: indexPath) as? BookSearchResultTableViewCell else {
            fatalError("Could not dequeue BookSearchResultTableViewCell")
        }

        let result = results[indexPath.row]
        cell.chapterNumberLabel.text = "Chapter \(result.chapterNumber)"
        cell.pageNumberLabel.text = "Page \(result.pageNumber)"
        cell.contentSearchLabel.text = result.content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = results[indexPath.row]
        print("Tapped on chapter \(result.chapterNumber), page \(result.pageNumber)")
        tableView.deselectRow(at: indexPath, animated: true)
        // Navigate or perform action here
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80 // or any fixed height you prefer
    }

}
