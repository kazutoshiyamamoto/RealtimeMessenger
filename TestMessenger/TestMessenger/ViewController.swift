//
//  ViewController.swift
//  TestMessenger
//
//  Created by home on 2018/05/20.
//  Copyright © 2018年 Swift-beginners. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController

class ViewController: JSQMessagesViewController {
    
    // データベースへの参照を定義
    var ref: DatabaseReference!
    
    // メッセージ内容に関するプロパティ
    var messages: [JSQMessage]?
    // 背景画像に関するプロパティ
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    // アバター画像に関するプロパティ
    var incomingAvatar: JSQMessagesAvatarImage!
    var outgoingAvatar: JSQMessagesAvatarImage!
    
    // 返答メッセージに関する辞書
    let respond: [String:String] = [
        "部屋のテイスト":"次のどのテイストのお部屋が好きですか？\nナチュラルor落ち着いたorクール",
        "ナチュラル":"それでしたらホワイト、ベージュ、ブラウンの色の家具の組み合わせがおすすめです！いかがですか？\nいいorよくない",
        "落ち着いた":"それでしたらブラック、ダークブラウン、白の色の家具の組み合わせがおすすめです！いかがですか？\nいいorよくない",
        "クール":"それでしたらホワイトとブラックの家具の組み合わせがおすすめです！いかがですか？\nいいorよくない",
        "いい":"よかったです！RoomClipのキーワード検索でより具体的なイメージを膨らませてみましょう！\n他に知りたいことはありますか？\n知りたいor大丈夫",
        "よくない":"他に気になるテイストはありますか？\nあるorない",
        "ある":"もう一度次から気になるテイストを選んでください\nナチュラルor落ち着いたorクール",
        "ない":"お力になれず残念です。。\n他に知りたいことはありますか？\n知りたいor大丈夫",
        "部屋が狭い":"高さの低い家具で統一するか、背の高い家具を部屋の手前に置くと広く見えますよ！\n他に知りたいことはありますか？\n知りたいor大丈夫",
        "知りたい":"知りたいことを教えてください。\n部屋のテイストor部屋が狭いor家具の配置",
        "大丈夫":"少しでもお手伝いできたなら嬉しいです！お部屋づくり楽しんでくださいね。",
        "家具の配置":"楽に通れるスペースを確保できるようにしましょう。掃除も楽ですよ！\n他に知りたいことはありますか？\n知りたいor大丈夫"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // クリーンアップツールバーの設定
        self.inputToolbar!.contentView!.leftBarButtonItem = nil
        // 新しいメッセージを受信するたびに下にスクロールする
        self.automaticallyScrollsToMostRecentMessage = true
        
        // 自分のsenderId, senderDisplayNameを設定
        self.senderId = "user1"
        self.senderDisplayName = "A"
        
        // 吹き出しの設定
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        self.incomingBubble = bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
        self.outgoingBubble = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        
        // アバターの設定
        self.incomingAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "snowman")!, diameter: 64)
        self.outgoingAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "santaclaus")!, diameter: 64)
        
        //メッセージデータの配列を初期化
        self.messages = []
        self.setupFirebase()
        
        // 過去のメッセージ取得後に会話開始時のメッセージを表示
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            self.testRecvMessage(responseText: "何か手伝えることはありますか？\n部屋のテイストor部屋が狭いor家具の配置")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // データベースからデータを取得する
    func setupFirebase() {
        // DatabaseReferenceのインスタンス化
        self.ref = Database.database().reference()
        
        // 最新5件のデータをデータベースから取得する
        // 最新のデータが追加されるたびに最新データを取得する
        self.ref.queryLimited(toLast: 10).observe(DataEventType.childAdded, with: { (snapshot) -> Void in
            let snapshotValue = snapshot.value as! NSDictionary
            let text = snapshotValue["text"] as! String
            let sender = snapshotValue["from"] as! String
            let name = snapshotValue["name"] as! String
            let message = JSQMessage(senderId: sender, displayName: name, text: text)
            self.messages?.append(message!)
            self.finishSendingMessage()
        })
    }
    
    // Sendボタンが押された時に呼ばれるメソッド
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        
        //メッセージの送信処理を完了する(画面上にメッセージが表示される)
        self.finishReceivingMessage(animated: true)
        
        //Firebaseにデータを送信、保存する
        let post1 = ["from": senderId, "name": senderDisplayName, "text":text]
        let post1Ref = self.ref.childByAutoId()
        post1Ref.setValue(post1)
        self.finishSendingMessage(animated: true)
        
        // Sendの内容に合わせて返答内容を変更する
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(50)) {
            guard let messageText = self.respond[text] else {
                self.testRecvMessage(responseText: "選択肢の中から選んで入力してください！")
                return
            }
            // 返答メッセージに関する辞書から値を取り出す
            self.testRecvMessage(responseText: messageText)
        }
    }
    
    // メッセージに対して返答する
    func testRecvMessage(responseText: String) {
        let post2 = ["from": "user2", "name": "B", "text":responseText]
        let post2Ref = self.ref.childByAutoId()
        post2Ref.setValue(post2)
    }
    
    // アイテムごとに参照するメッセージデータを返す
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
        return messages![indexPath.item]
    }
    
    // アイテムごとのMessageBubble(背景)を返す
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource {
        let message = self.messages?[indexPath.item]
        if message?.senderId == self.senderId {
            return self.outgoingBubble
        }
        return self.incomingBubble
    }
    
    // アイテムごとにアバター画像を返す
    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        let message = self.messages?[indexPath.item]
        if message?.senderId == self.senderId {
            return self.outgoingAvatar
        }
        return self.incomingAvatar
    }
    
    // アイテムの総数を返す
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages!.count
    }
}

