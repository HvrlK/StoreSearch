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
    
    // MARK: - Outlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.removeConstraints(view.constraints)
        view.translatesAutoresizingMaskIntoConstraints = true
        pageControl.removeConstraints(pageControl.constraints)
        pageControl.translatesAutoresizingMaskIntoConstraints = true
        scrollView.removeConstraints(scrollView.constraints)
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        scrollView.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
        pageControl.numberOfPages = 0
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        scrollView.frame = view.bounds
        pageControl.frame = CGRect(
            x: 0,
            y: view.frame.size.height - pageControl.frame.size.height,
            width: view.frame.size.width,
            height: pageControl.frame.size.height
        )
        if firstTime {
            firstTime = false
            switch search.state {
            case .notSearchedYet:
                break
            case .loading:
                showSpinner()
            case .noResults:
                showNothingFoundLabel()
            case .results(let list):
                tileButtons(list)
            }
        }
    }
    
    // FIXME: supporting iphone X and use collection view 
    private func tileButtons(_ searchResults: [SearchResult]) {
        var columnsPerPage = 5
        var rowsPerPage = 3
        var itemWidth: CGFloat = 96
        var itemHeight: CGFloat = 88
        var marginX: CGFloat = 0
        var marginY: CGFloat = 20
        let scrollViewWidth = scrollView.bounds.size.width
        switch scrollViewWidth {
        case 568:
            columnsPerPage = 6
            itemWidth = 94
            marginX = 2
        case 667:
            columnsPerPage = 7
            itemWidth = 95
            itemHeight = 98
            marginX = 1
            marginY = 29
        case 736:
            columnsPerPage = 8
            rowsPerPage = 4
            itemWidth = 92
        default:
            break
        }
        let buttonWidth: CGFloat = 82
        let buttonHeight: CGFloat = 82
        let paddingHorz = (itemWidth - buttonWidth)/2
        let paddingVert = (itemHeight - buttonHeight)/2
        var row = 0
        var column = 0
        var x = marginX
        for (index, searchResult) in searchResults.enumerated() {
            let button = UIButton(type: .custom)
            button.setBackgroundImage(UIImage(named: "LandscapeButton"), for: .normal)
            downloadImage(for: searchResult, andPlaceOn: button)
            button.frame = CGRect(
                x: x + paddingHorz,
                y: marginY + CGFloat(row)*itemHeight + paddingVert,
                width: buttonWidth, height: buttonHeight)
            button.tag = 2000 + index
            button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
            scrollView.addSubview(button)
            row += 1
            if row == rowsPerPage {
                row = 0; x += itemWidth; column += 1
                if column == columnsPerPage {
                    column = 0; x += marginX * 2
                }
            }
        }
        let buttonsPerPage = columnsPerPage * rowsPerPage
        let numPages = 1 + (searchResults.count - 1) / buttonsPerPage
        scrollView.contentSize = CGSize(
            width: CGFloat(numPages)*scrollViewWidth,
            height: scrollView.bounds.size.height)
        pageControl.numberOfPages = numPages
        pageControl.currentPage = 0
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowDetail", sender: sender)
    }
    
    private func downloadImage(for searchResult: SearchResult, andPlaceOn button: UIButton) {
        if let url = URL(string: searchResult.artworkSmallURL) {
            let downloadTask = URLSession.shared.downloadTask(with: url) {
                [weak button] url, response, error in
                if error == nil, let url = url,
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if let button = button {
                            button.setImage(image, for: .normal)
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
        spinner.center = CGPoint(x: scrollView.bounds.midX + 0.5, y: scrollView.bounds.midY + 0.5)
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
        case .results(let list):
            tileButtons(list)
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
        label.center = CGPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY)
        view.addSubview(label)
    }
    
    deinit {
        print("deinit \(self)")
        downloadTasks.forEach { $0.cancel() }
    }
    
    // MARK: Actions
    
    @IBAction func pageChanged(_ sender: UIPageControl) {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: [.curveEaseInOut], animations: {
                self.scrollView.contentOffset = CGPoint(
                    x: self.scrollView.bounds.size.width * CGFloat(sender.currentPage),
                    y: 0
                )}, completion: nil
        )
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            if case .results(let list) = search.state {
                let detailViewController = segue.destination as! DetailViewController
                let searchResult = list[(sender as! UIButton).tag - 2000]
                detailViewController.searchResult = searchResult
            }
        }
    }
    
}

// MARK: - Extensions

extension LandscapeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        let currentPage = Int((scrollView.contentOffset.x + width/2)/width)
        pageControl.currentPage = currentPage
    }
}

