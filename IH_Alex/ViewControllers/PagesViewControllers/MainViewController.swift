//
//  MainViewController.swift
//  IH_Alex
//
//  Created by Esther Elzek on 29/04/2025.
//

import UIKit

class MainViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UISearchBarDelegate, BookSearchDelegate {
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
    
    private let lastThreePagesKey = "LastThreePages"
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
        slider.minimumValue = 0
        slider.maximumValue = Float(pagedVC?.pages.count ?? 1) - 1
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        let tapGestureslider = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(_:)))
        slider.addGestureRecognizer(tapGestureslider)


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
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let pageIndex = Int(sender.value.rounded())
        updateCurrentPageLabels()
        guard let pageController = self.pagedVC else { return }
        pageController.currentIndex = pageIndex
        
        if let targetVC = pageController.getViewController(at: pageIndex) {
            pageController.pageViewController.setViewControllers(
                [targetVC],
                direction: .forward,
                animated: false,
                completion: { finished in
                    print("✅ Navigated to page \(pageIndex) by sliding the slider.")
                }
            )
        }
        pageController.pageControl.currentPage = pageIndex
        savePageToUserDefaults(pageIndex)
        updatePageMarkers()
    }

    @objc func sliderTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        let tapLocation = gestureRecognizer.location(in: slider)
        let sliderWidth = slider.bounds.width
        let tappedValueRatio = tapLocation.x / sliderWidth
        let newValue = Float(tappedValueRatio) * (slider.maximumValue - slider.minimumValue) + slider.minimumValue
        slider.setValue(newValue, animated: true)
        let pageIndex = Int(newValue.rounded())
        updateCurrentPageLabels()
        guard let pageController = self.pagedVC else { return }
        pageController.currentIndex = pageIndex
        if let targetVC = pageController.getViewController(at: pageIndex) {
            pageController.pageViewController.setViewControllers(
                [targetVC],
                direction: .forward,
                animated: false,
                completion: { finished in
                    print("✅ Navigated to page \(pageIndex) by tapping slider.")
                }
            )
        }
        pageController.pageControl.currentPage = pageIndex
        savePageToUserDefaults(pageIndex)
        updatePageMarkers()
    }


    @IBAction func searchButtonTapped(_ sender: Any) {
        let searchVC = BookSearchResultViewController()
        searchVC.pageController = self.pagedVC
        searchVC.pages = pagedVC?.pages ?? []
        searchVC.metadata = pagedVC?.metadataa
        searchVC.delegate = self
        searchVC.modalPresentationStyle = .overCurrentContext
        searchVC.modalTransitionStyle = .crossDissolve
        present(searchVC, animated: true)
    }
    
    @IBAction func resetStateButton(_ sender: Any) {
        self.slider.isHidden = false
        self.searchBar.isHidden = true
        self.resetStateButton.isHidden = true
    }
    
    @IBAction func dropDownButton(_ sender: Any) {
    }
    
    @objc func contentViewTapped() {
        topBar.isHidden.toggle()
        bottomBar.isHidden.toggle()
    }
}

extension MainViewController {
    func didSelectSearchResult(_ result: SearchResult) {
        guard let index = pagedVC?.pages.firstIndex(where: {
            $0.pageNumberInBook == result.pageNumber
        }) else { return }
        pagedVC?.getViewController(at: index)
        updateCurrentPageLabels()
    }
}

extension MainViewController: PagedTextViewControllerDelegate {
    func didUpdatePage(to index: Int) {
        pagedVC?.currentIndex = index
        updateCurrentPageLabels()
        slider.setValue(Float(index), animated: true)
        if let currentTextPageVC = pagedVC?.currentTextPageViewController() {
            currentTextPageVC.internalLinkDelegate = self
        }
        savePageToUserDefaults(index) // Save the page to the last three
        updatePageMarkers()
    }

    func updatePageMarkers() {
        let lastThreePages = getLastThreePages()
        slider.subviews.forEach { subview in
            if subview.tag == 999 { // Custom tag to identify
                subview.removeFromSuperview()
            }
        }
        
        for pageIndex in lastThreePages {
            if pageIndex == Int(slider.value.rounded()) {
                continue
            }
            let marker = UIView()
            marker.tag = 999
            marker.backgroundColor = .systemCyan
            marker.layer.cornerRadius = 5
            let markerX = CGFloat(pageIndex) / CGFloat(slider.maximumValue) * slider.frame.width - 5
            if abs(markerX - slider.frame.width * CGFloat(slider.value) / CGFloat(slider.maximumValue)) < 10 {
                continue
            }
            marker.frame = CGRect(x: markerX,
                                  y: slider.frame.height / 2 - 5,
                                  width: 10,
                                  height: 10)
            slider.addSubview(marker)
        }
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
       
        print("currentPageComparedToChapterPages.text: \(String(describing: currentPageComparedToChapterPages.text))")
        print("currentPageComparedToBookPages.text: \(String(describing: currentPageComparedToBookPages.text))")
    }

  func setUpInformation() {
      print("pagedVC?.bookInfo?.name : \(String(describing: pagedVC?.bookResponse?.book))")
       bookTitleLabel.text = pagedVC?.bookResponse?.book.name
      func setUpInformation() {
          guard let totalPages = pagedVC?.pages.count else { return }
          slider.minimumValue = 0
          slider.maximumValue = Float(totalPages) - 1
          slider.isContinuous = true
      }

    }
    

    func savePageToUserDefaults(_ pageIndex: Int) {
        var lastPages = UserDefaults.standard.array(forKey: lastThreePagesKey) as? [Int] ?? []
        lastPages.removeAll { $0 == pageIndex }
        lastPages.insert(pageIndex, at: 0)
        if lastPages.count > 4 {
            lastPages.removeLast()
        }
        UserDefaults.standard.set(lastPages, forKey: lastThreePagesKey)
    }

    func getLastThreePages() -> [Int] {
        var lastPages = UserDefaults.standard.array(forKey: lastThreePagesKey) as? [Int] ?? []
        if let currentPageIndex = Int(exactly: slider.value) {
            lastPages.removeAll { $0 == currentPageIndex }
        }
        return Array(lastPages.prefix(4))
    }


    func preparePager() {
        let pagedVC = PagedTextViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pagedVC.pageChangeDelegate = self
        self.pagedVC = pagedVC
        pagedVC.pageChangeDelegate = self
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
        if let currentTextPageVC = pagedVC.currentTextPageViewController() {
            currentTextPageVC.internalLinkDelegate = self
        }
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
extension MainViewController: InternalLinkNavigationDelegate {
    func didNavigateToInternalLink(pageIndex: Int) {
        print("🌟 Navigated to page: \(pageIndex) from internal link")
        slider.setValue(Float(pageIndex), animated: true)
        pagedVC?.currentIndex = pageIndex
        updateCurrentPageLabels()
        savePageToUserDefaults(pageIndex) // Save the page to the last three
        updatePageMarkers()
    }
}
