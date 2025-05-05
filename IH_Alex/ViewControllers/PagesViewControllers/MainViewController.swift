//
//  MainViewController.swift
//  IH_Alex
//
//  Created by Esther Elzek on 29/04/2025.
//

import UIKit

class MainViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UISearchBarDelegate {


    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var currentPageComparedToChapterPages: UILabel!
    @IBOutlet weak var currentPageComparedToBookPages: UILabel!
    @IBOutlet weak var chapterTitleLabel: UILabel!
    @IBOutlet weak var resetStateButton: UIButton!
    var pageViewController: UIPageViewController!
    var pages: [UIViewController] = []
    let pageControl = UIPageControl()
    var currentIndex = 0
    var menuVC: MenuViewController?
    var pagedVC: PagedTextViewController?
    var isOpenedMenu: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topBar.isHidden = true
        bottomBar.isHidden = true
        searchBar.delegate = self
        preparePager()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(contentViewTapped))
        contentView.addGestureRecognizer(tapGesture)
        setUpInformation()
        updateCurrentPageLabels()
        registerForKeyboardNotifications()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Button Actions
    @IBAction func menuButton(_ sender: Any) {}
    @IBAction func editingButton(_ sender: Any) {
        guard let textPageVC = pagedVC?.currentTextPageViewController() else {
            print("❌ Could not retrieve current TextPageViewController")
            return
        }
            textPageVC.toggleMenu()
    }

    @IBAction func backButtonTapped(_ sender: Any) {}
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        self.searchBar.isHidden = false
        self.resetStateButton.isHidden = false
        self.slider.isHidden = true
    }
    
    @IBAction func resetStateButton(_ sender: Any) {
        self.slider.isHidden = false
        self.searchBar.isHidden = true
        self.resetStateButton.isHidden = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() // hide keyboard

        let searchVC = BookSearchResultViewController()
        searchVC.modalPresentationStyle = .overCurrentContext
        searchVC.modalTransitionStyle = .crossDissolve
        self.definesPresentationContext = true
        present(searchVC, animated: true, completion: nil)
    }
    
    @objc func contentViewTapped() {
        view.endEditing(true) // ✅ Hide keyboard
        let shouldHide = !topBar.isHidden
        UIView.animate(withDuration: 0.3) {
            self.topBar.alpha = shouldHide ? 0 : 1
            self.bottomBar.alpha = shouldHide ? 0 : 1
        } completion: { _ in
            self.topBar.isHidden = shouldHide
            self.bottomBar.isHidden = shouldHide
        }
    }


}

extension MainViewController: PagedTextViewControllerDelegate {
    func didUpdatePage(to index: Int) {
        pagedVC?.currentIndex = index
        updateCurrentPageLabels()
    }
    func updateCurrentPageLabels() {
        guard let pagedVC = pagedVC else { return }
        let currentIndex = pagedVC.currentIndex
        let currentPage = pagedVC.pages[currentIndex]
        let globalPageIndex = currentPage.pageNumberInBook - 1 // 0-based
        var displayChapterNumber = currentPage.chapterNumber
        var pageInChapter = 1
        var totalChapterPages = 1
        var chapterName = "Chapter \(displayChapterNumber)"
        if let indexList = pagedVC.metadataa?.decodedIndex() {
            var cumulative = 0
            for chapter in indexList {
                let chapterCount = chapter.chapterPagesCount ?? 0
                if globalPageIndex < cumulative + chapterCount {
                    displayChapterNumber = chapter.number
                    totalChapterPages = chapterCount
                    pageInChapter = globalPageIndex - cumulative + 1
                    chapterName = chapter.name
                    break
                }
                cumulative += chapterCount
            }
        } else {
            let chapterPages = pagedVC.pages.filter { $0.chapterNumber == currentPage.chapterNumber }
            pageInChapter = (chapterPages.firstIndex(of: currentPage) ?? 0) + 1
            totalChapterPages = chapterPages.count
            chapterName = "Chapter \(displayChapterNumber)"
        }

        let totalBookPages = pagedVC.pages.count
        let pageInBook = currentPage.pageNumberInBook
        chapterTitleLabel.text = chapterName
        currentPageComparedToChapterPages.text = "chapter:\(displayChapterNumber): Page \(pageInChapter) / \(totalChapterPages)"
        currentPageComparedToBookPages.text = "Page \(pageInBook) / \(totalBookPages)"
    }

  func setUpInformation() {
      print("pagedVC?.bookInfo?.name : \(String(describing: pagedVC?.bookResponse?.book))")
       bookTitleLabel.text = pagedVC?.bookResponse?.book.name
    }
    
    func preparePager() {
        let pagedVC = PagedTextViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pagedVC.pageChangeDelegate = self // ✅ Set delegate here after instantiating
        self.pagedVC = pagedVC // store reference
        addChild(pagedVC)
        contentView.addSubview(pagedVC.view)
        pagedVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagedVC.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            pagedVC.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            pagedVC.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pagedVC.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        pagedVC.didMove(toParent: self)
    }

    private func setupPages() {
        let colors: [UIColor] = [.red, .green, .blue]
        pages = colors.map { color in
            let vc = UIViewController()
            vc.view.backgroundColor = color
            return vc
        }
    }
}

extension MainViewController {
    private func setupPageViewController() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([pages[0]], direction: .forward, animated: false)
        addChild(pageViewController)
        contentView.addSubview(pageViewController.view)
        pageViewController.view.frame = contentView.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageViewController.didMove(toParent: self)
    }

    private func setupPageControl() {
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = currentIndex
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -8),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        let keyboardHeight = keyboardFrame.height
        UIView.animate(withDuration: animationDuration) {
            self.bottomBar.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        UIView.animate(withDuration: animationDuration) {
            self.bottomBar.transform = .identity
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index > 0 else { return nil }
        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let currentVC = pageViewController.viewControllers?.first,
           let index = pages.firstIndex(of: currentVC) {
            currentIndex = index
            pageControl.currentPage = index
        }
    }
    
}
