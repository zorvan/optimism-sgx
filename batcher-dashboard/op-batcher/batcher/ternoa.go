package batcher

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
)

type PostBody struct {
	TxHash  string `json:"txid"`
	BlockId string `json:"blockid"`
}

type Post struct {
	Id     int      `json:"id"`
	Title  string   `json:"title"`
	Body   PostBody `json:"body"`
	UserId int      `json:"userId"`
}

func ternoa(txid string, blockid string) {
	posturl := "http://dev-c1n1.ternoa.network:9876"
	ids := fmt.Sprintf(`{"txid": "%s", "blockid": "%s"}`, txid, blockid)
	bodys := fmt.Sprintf(`{"id": 1,"title": "Batcher Transaction Confirmed","body": %s,"userId": 1}`, ids)
	body := []byte(bodys)

	r, err := http.NewRequest("POST", posturl, bytes.NewBuffer(body))
	if err != nil {
		fmt.Println("Err-0:", err)
		return
	}

	r.Header.Add("Content-Type", "application/json")

	client := &http.Client{}
	res, err := client.Do(r)
	if err != nil {
		fmt.Println("Err-1:", err)
		return
	}

	defer res.Body.Close()

	post := &Post{}
	derr := json.NewDecoder(res.Body).Decode(post)
	if derr != nil {
		fmt.Println("Err-2:", derr)
		return
	}

	fmt.Println("Dashboard Status Code: ", res.Status)
	fmt.Println("Dashboard Res Body:", post.Body)
}
