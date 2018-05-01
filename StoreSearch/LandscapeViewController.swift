//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by Vitalii Havryliuk on 4/29/18.
//  Copyright © 2018 Vitalii Havryliuk. All rights reserved.
//

import UIKit

class LandscapeViewController: UIViewController {
    
    // MARK: - Properties
    
    var search: Search!
    private var firstTime = true
    private var downloadTasks = [URLSessionDownloadTask]()
    private var flowLayout: UICollectionViewFlowLayout? {
        return collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
        pageControl.numberOfPages = 0
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        rightSwipe.direction = .right
        collectionView.addGestureRecognizer(rightSwipe)
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        leftSwipe.direction = .left
        collectionView.addGestureRecognizer(leftSwipe)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if firstTime {
            firstTime = false
            switch search.state {
            case .notSearchedYet:
                break
            case .loading:
                showSpinner()
            case .noResults:
                showNothingFoundLabel()
            case .results:
                break
            }
        }
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .right {
            pageControl.currentPage = pageControl.currentPage - 1
            pageDidChange()
        } else {
            pageControl.currentPage = pageControl.currentPage + 1
            pageDidChange()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if case .results(let list) = search.state {
            let itemPerRow: Int = Int(collectionView.frame.size.width / 82.0)
            let line = (Double(collectionView.frame.size.width) - Double(itemPerRow) * 82) / (Double(itemPerRow))
            let pageCount = 1 + list.count / (itemPerRow * 3)
            flowLayout?.minimumLineSpacing = CGFloat(line)
            flowLayout?.sectionInset.left = CGFloat(line / 2)
            flowLayout?.invalidateLayout()
            pageControl.numberOfPages = pageCount
        }
    }
    
    private func downloadImage(for searchResult: SearchResult, andPlaceOn imageView: UIImageView) {
        if let url = URL(string: searchResult.artworkSmallURL) {
            let downloadTask = URLSession.shared.downloadTask(with: url) {
                [weak imageView] url, response, error in
                if error == nil, let url = url,
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if let imageView = imageView {
                            imageView.image = image
                        }
                    }
                }
            }
            downloadTask.resume()
            downloadTasks.append(downloadTask)
        }
    }
    
    private func showSpinner() {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.center = CGPoint(x: view.bounds.midX + 0.5, y: view.bounds.midY + 0.5)
        spinner.tag = 1000
        view.addSubview(spinner)
        spinner.startAnimating()
    }
    
    func searchResultsReceived() {
        hideSpinner()
        switch search.state {
        case .notSearchedYet, .loading:
            break
        case .noResults:
            showNothingFoundLabel()
        case .results:
            collectionView.reloadData()
        }
    }
    
    private func hideSpinner() {
        view.viewWithTag(1000)?.removeFromSuperview()
    }
    
    func showNothingFoundLabel() {
        let label = UILabel(frame: CGRect.zero)
        label.text = NSLocalizedString("Nothing Found", comment: "Nothing Found: label")
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.clear
        label.sizeToFit()
        var rect = label.frame
        rect.size.width = ceil(rect.size.width / 2) * 2
        rect.size.height = ceil(rect.size.height / 2) * 2
        label.frame = rect
        label.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        view.addSubview(label)
    }
    
    func pageDidChange() {
        collectionView.setContentOffset(CGPoint(
            x: self.collectionView.bounds.size.width * CGFloat(pageControl.currentPage),
            y: 0
        ), animated: true)
    }
    
    deinit {
        print("deinit \(self)")
        downloadTasks.forEach { $0.cancel() }
    }
    
    // MARK: Actions
    
    @IBAction func pageChanged(_ sender: UIPageControl) {
        pageDidChange()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            if case .results(let list) = search.state {
                let detailViewController = segue.destination as! DetailViewController
                if let cell = sender as? LandscapeCell, let indexPath = collectionView.indexPath(for: cell) {
                    let searchResult = list[indexPath.item]
                    detailViewController.searchResult = searchResult
                    detailViewController.isPopUp = true
                }
            }
        }
    }
    
}

// MARK: - Extensions

extension LandscapeViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        let x = scrollView.contentOffset.x
        pageControl.currentPage = Int(ceil(x/width))
    }
    
}

extension LandscapeViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch search.state {
        case .results(let list):
            return list.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath)
        if let landscapeCell = cell as? LandscapeCell, case .results(let list) = search.state {
            downloadImage(for: list[indexPath.item], andPlaceOn: landscapeCell.imageView)
        }
        return cell
    }

}

