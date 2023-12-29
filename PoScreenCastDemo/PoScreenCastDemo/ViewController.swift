//
//  ViewController.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/8.
//

import UIKit
import PoScreenCast

class ViewController: UIViewController {
    
    var tableView: UITableView!
    var deviceList: [CastDevice] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupUI()
    }
    
    func setupUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "开始搜索", style: .plain, target: self, action: #selector(startSearch))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "停止搜索", style: .plain, target: self, action: #selector(stopSearch))
        
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 44
        tableView.estimatedRowHeight = 0
        tableView.register(DeviceCell.self, forCellReuseIdentifier: NSStringFromClass(DeviceCell.self))
        
        view.addSubview(tableView)
    }
    
    @objc
    private func startSearch() {
        CastDeviceManager.shared.delegate = self
        CastDeviceManager.shared.startSearch(searchTimes: 1, searchInterval: 0)
    }
    
    @objc
    private func stopSearch() {
        CastDeviceManager.shared.stopSearch()
        deviceList = []
        tableView.reloadData()
    }
}

extension ViewController: UITableViewDataSource {
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        deviceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DeviceCell.self), for: indexPath) as! DeviceCell
        
        let device = deviceList[indexPath.row]
        cell.titleLabel.text = device.friendlyName
        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = CastControlViewController()
        vc.castDevice = deviceList[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ViewController: CastDeviceManagerDelegate {
    
    func deviceManager(_ manager: CastDeviceManager, searchedDeviceListChange deviceList: [CastDevice]) {
        self.deviceList = deviceList
        tableView.reloadData()
    }
    
    func deviceManager(_ manager: CastDeviceManager, searchErrorOccured error: CastError.SearchDeviceError) {
        print(error)
    }
    
}

private final class DeviceCell: UITableViewCell {
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .red
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
    }
}
