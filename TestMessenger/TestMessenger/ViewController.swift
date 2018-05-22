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
        "ナチュラル":"ホワイト、ベージュ、ブラウンの色の家具の組み合わせでできますよ！いかがですか？\nいいorよくない",
        "落ち着いた":"ブラック、ダークブラウン、白の色の家具の組み合わせでできますよ！いかがですか？\nいいorよくない",
        "クール":"ホワイトとブラックの家具の組み合わせでできますよ！いかがですか？\nいいorよくない",
        "いい":"よかったです！ルームクリップのキーワード検索で具体的なイメージを膨らませていきましょう！",
        "よくない":"他に気になるテイストはありますか？\nあるorない",
        "ある":"もう一度次から気になるテイストを選んでください\nナチュラルor落ち着いたorクール",
        "ない":"お力になれず残念です。。ルームクリップのキーワード検索では様々なお部屋の画像がありますので、是非使ってみてください！"
    ]
    
    func setupFirebase() {
        // DatabaseReferenceのインスタンス化
        ref = Database.database().reference()
        
        // 最新25件のデータをデータベースから取得する
        // 最新のデータが追加されるたびに最新データを取得する
        ref.queryLimited(toLast: 25).observe(DataEventType.childAdded, with: { (snapshot) -> Void in
            let snapshotValue = snapshot.value as! NSDictionary
            let text = snapshotValue["text"] as! String
            let sender = snapshotValue["from"] as! String
            let name = snapshotValue["name"] as! String
            let message = JSQMessage(senderId: sender, displayName: name, text: text)
            self.messages?.append(message!)
            self.finishSendingMessage()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // クリーンアップツールバーの設定
        inputToolbar!.contentView!.leftBarButtonItem = nil
        // 新しいメッセージを受信するたびに下にスクロールする
        automaticallyScrollsToMostRecentMessage = true
        
        // 自分のsenderId, senderDisplayNameを設定
        self.senderId = "user1"
        self.senderDisplayName = "A"
        
        // 吹き出しの設定
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        self.incomingBubble = bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
        self.outgoingBubble = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        
        // アバターの設定
        self.incomingAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "Swift-Logo")!, diameter: 64)
        self.outgoingAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "Swift-Logo")!, diameter: 64)
        
        //メッセージデータの配列を初期化
        self.messages = []
        setupFirebase()
        
        // 会話開始時のメッセージを表示
        testRecvMessage(responseText: "次のどのテイストのお部屋が好きですか？\nナチュラルor落ち着いたorクール")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Sendボタンが押された時に呼ばれるメソッド
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        
        //メッセージの送信処理を完了する(画面上にメッセージが表示される)
        self.finishReceivingMessage(animated: true)
        
        //Firebaseにデータを送信、保存する
        let post1 = ["from": senderId, "name": senderDisplayName, "text":text]
        let post1Ref = ref.childByAutoId()
        post1Ref.setValue(post1)
        self.finishSendingMessage(animated: true)
        
        //キーボードを閉じる
        self.view.endEditing(true)
        
        // Sendの内容に合わせて返答内容を変更する
        guard let messageText = respond[text] else {
            testRecvMessage(responseText: "わかりませんでした")
            return
        }
        // 返答メッセージに関する辞書から値を取り出す
        testRecvMessage(responseText: messageText)
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
    
    // メッセージに対して返答する
    func testRecvMessage(responseText: String) {
        let message = JSQMessage(senderId: "user2", displayName: "B", text: responseText)
        self.messages?.append(message!)
        self.finishReceivingMessage(animated: true)
    }
}
