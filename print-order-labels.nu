#!/usr/bin/env nu

const base_url = "https://app.ecwid.com/api/v3/96539012/"
let headers = {Authorization: $"Bearer ($env.access_token)"}

const order_dir = "orders"

mkdir -v $order_dir

def ecwid_fetch [path] {
  http get $'($base_url)($path)' --headers $headers
}

def save_pdf [id] {
    http get $'($base_url)orders/($id)/invoice-pdf' --headers $headers out> $"./($order_dir)/($id).pdf"
}


def get_order [id] {
  ecwid_fetch $'orders/($id)'
}

def fetch_orders [search] {
  let query = $search | url build-query
  ecwid_fetch $'orders?($query)'
  | get items
}

let ready_to_print = { 
    fulfillmentStatus:"PROCESSING,AWAITING_PROCESSING"
    , containsPreorderItems:"false"
    , responseFields: "items(id,email,total)"
    }


def ready_orders [] {
  fetch_orders $ready_to_print
}


def process_new_label [id] {
    let filename = $"($id).pdf"

    let exists = (ls $"($order_dir)" | where name == $"($order_dir)/($filename)" | is-not-empty)

    if $exists {
        print $"Already have ($id).pdf"
    } else {
        save_pdf $id
        print $"Saved ($id).pdf. Printing!"
        #^print $"($order_dir)/($filename)"
    }
}


def main [] {
  ready_orders | par-each { process_new_label $in.id }
}