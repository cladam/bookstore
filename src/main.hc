import "sqlite"
import "imgui"
import "csv"
import "./bookstore-ui_theme"

struct SeedBook {
  title: string,
  author: string,
  distributor: string,
  section: string,
  barcode: string,
  retail_price: string,
  purchase_cost: string,
  current_stock: string,
  first_stocked_date: string
}

struct SeedSale {
  sales_month: string,
  title: string,
  net_units: string,
  sales_incl_vat: string
}

// Title Normalization helper to map/merge inventory & sales correctly
fun normalize_title(s: string) : string {
  let cs = chars(s)
  let filtered = filter(cs, is_alnum)
  to_lower(from_chars(filtered))
}

// Skip Google Docs CSV metadata lines
fun skip_metadata(content: string) : string {
  unlines(drop(lines(content), 2))
}

// Import real CSV datasets from Docs
fun import_real_data(db) : string {
  match read_file("docs/Inventory - Current Inventory.csv") {
    Err(e) => "Error reading inventory CSV: " + e,
    Ok(inv_text) => {
      let clean_inv = skip_metadata(inv_text)
      let t_inv = csv_parse(clean_inv)
      for row in t_inv.rows {
        let title = match str_at(row, 0) { None => "", Some(s) => s }
        if title != "" {
          let author = match str_at(row, 1) { None => "", Some(s) => s }
          let distributor = match str_at(row, 2) { None => "", Some(s) => s }
          let section = match str_at(row, 3) { None => "", Some(s) => s }
          let barcode = match str_at(row, 5) { None => "", Some(s) => s }
          let retail_price = match str_at(row, 6) { None => "0.0", Some(s) => s }
          let purchase_cost = match str_at(row, 7) { None => "0.0", Some(s) => s }
          let current_stock = match str_at(row, 8) { None => "0", Some(s) => s }
          let first_stocked_date = match str_at(row, 10) { None => "", Some(s) => s }
          let mk = normalize_title(title)
          let stock_val = match parse_float(current_stock) {
            None => 0.0,
            Some(st) => match parse_float(purchase_cost) {
              None => 0.0,
              Some(co) => st * co
            }
          }

          let sql = "INSERT INTO inventory (title, author, distributor, section, barcode, retail_price, purchase_cost, current_stock, stock_value, first_stocked_date, match_key) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(match_key) DO UPDATE SET current_stock=excluded.current_stock, stock_value=excluded.stock_value, first_stocked_date=excluded.first_stocked_date"
          let _ = sqlite_exec_p(db, sql, [
            param(title), param(author), param(distributor), param(section),
            param(barcode), param(retail_price), param(purchase_cost), param(current_stock),
            param(show(stock_val)), param(first_stocked_date), param(mk)
          ])
          ()
        } else {
          ()
        }
      }

      match read_file("docs/Inventory - Sales History.csv") {
        Err(e) => "Inventory imported, but error reading sales history CSV: " + e,
        Ok(sales_text) => {
          let clean_sales = skip_metadata(sales_text)
          let t_sales = csv_parse(clean_sales)
          for row in t_sales.rows {
            let m = match str_at(row, 0) { None => "", Some(s) => s }
            let title = match str_at(row, 1) { None => "", Some(s) => s }
            if m != "" && title != "" {
              let net_units = match str_at(row, 9) { None => "0", Some(s) => s }
              let sales_incl_vat = match str_at(row, 12) { None => "0.0", Some(s) => s }
              let mk = normalize_title(title)

              let sql = "INSERT INTO sales_history (sales_month, title, net_units, sales_incl_vat, match_key) VALUES (?, ?, ?, ?, ?)"
              let _ = sqlite_exec_p(db, sql, [
                param(m), param(title), param(net_units), param(sales_incl_vat), param(mk)
              ])
              ()
            } else {
              ()
            }
          }
          "Successfully loaded actual database with full current inventory and sales history records!"
        }
      }
    }
  }
}

// Database schema initialization
fun init_db(db) {
  let _ = sqlite_exec(db, "CREATE TABLE IF NOT EXISTS inventory (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, author TEXT, distributor TEXT, section TEXT, sku TEXT, barcode TEXT, retail_price REAL, purchase_cost REAL, current_stock INTEGER, stock_value REAL, first_stocked_date TEXT, match_key TEXT UNIQUE)")

  let _ = sqlite_exec(db, "CREATE TABLE IF NOT EXISTS sales_history (id INTEGER PRIMARY KEY AUTOINCREMENT, sales_month TEXT NOT NULL, title TEXT NOT NULL, net_units INTEGER, sales_incl_vat REAL, match_key TEXT)")

  let _ = sqlite_exec(db, "CREATE TABLE IF NOT EXISTS overrides (match_key TEXT PRIMARY KEY, status_override TEXT, manual_target INTEGER, is_hard_to_source INTEGER, always_reorder INTEGER)")
}

// Safe seeding of realistic data if DB is empty
fun seed_data_if_empty(db) {
  match sqlite_query(db, "SELECT COUNT(*) FROM inventory") {
    Err(_) => { () },
    Ok(res) => {
      let count = match res.rows {
        [] => 0,
        [row, .._] => match row_int(row, 0) {
          None => 0,
          Some(v) => v
        }
      }
      if count == 0 {
        // Seed Inventory
        let books = [
          SeedBook { title: "The Great Gatsby", author: "F. Scott Fitzgerald", distributor: "Distributor A", section: "Fiction", barcode: "9780743273565", retail_price: "150.0", purchase_cost: "75.0", current_stock: "5", first_stocked_date: "2026-01-10" },
          SeedBook { title: "To Kill a Mockingbird", author: "Harper Lee", distributor: "Distributor A", section: "Fiction", barcode: "9780446310789", retail_price: "160.0", purchase_cost: "80.0", current_stock: "0", first_stocked_date: "2025-08-15" },
          SeedBook { title: "1984", author: "George Orwell", distributor: "Distributor B", section: "Sci-Fi", barcode: "9780451524935", retail_price: "140.0", purchase_cost: "70.0", current_stock: "1", first_stocked_date: "2026-02-01" },
          SeedBook { title: "Pride and Prejudice", author: "Jane Austen", distributor: "Distributor B", section: "Classics", barcode: "9780141439518", retail_price: "120.0", purchase_cost: "60.0", current_stock: "3", first_stocked_date: "2024-05-10" },
          SeedBook { title: "Crime and Punishment", author: "Fyodor Dostoevsky", distributor: "Distributor C", section: "Classics", barcode: "9780140449136", retail_price: "180.0", purchase_cost: "90.0", current_stock: "2", first_stocked_date: "2025-11-20" },
          SeedBook { title: "Sapiens", author: "Yuval Noah Harari", distributor: "Distributor C", section: "History", barcode: "9780062316097", retail_price: "220.0", purchase_cost: "110.0", current_stock: "0", first_stocked_date: "2026-03-01" },
          SeedBook { title: "Thinking, Fast and Slow", author: "Daniel Kahneman", distributor: "Distributor A", section: "Science", barcode: "9780374533557", retail_price: "200.0", purchase_cost: "100.0", current_stock: "4", first_stocked_date: "2025-06-15" }
        ]

        for book in books {
          let mk = normalize_title(book.title)
          let stock_val = match parse_float(book.current_stock) {
            None => 0.0,
            Some(st) => match parse_float(book.purchase_cost) {
              None => 0.0,
              Some(co) => st * co
            }
          }

          let sql = "INSERT INTO inventory (title, author, distributor, section, barcode, retail_price, purchase_cost, current_stock, stock_value, first_stocked_date, match_key) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
          let _ = sqlite_exec_p(db, sql, [
            param(book.title), param(book.author), param(book.distributor), param(book.section),
            param(book.barcode), param(book.retail_price), param(book.purchase_cost), param(book.current_stock),
            param(show(stock_val)), param(book.first_stocked_date), param(mk)
          ])
        }

        // Seed Sales History (simulating recent 90 and 180 day sales)
        let sales = [
          SeedSale { sales_month: "2026-05", title: "The Great Gatsby", net_units: "3", sales_incl_vat: "450.0" },
          SeedSale { sales_month: "2026-06", title: "The Great Gatsby", net_units: "2", sales_incl_vat: "300.0" },
          SeedSale { sales_month: "2026-07", title: "The Great Gatsby", net_units: "4", sales_incl_vat: "600.0" },
          SeedSale { sales_month: "2026-04", title: "1984", net_units: "1", sales_incl_vat: "140.0" },
          SeedSale { sales_month: "2026-05", title: "1984", net_units: "2", sales_incl_vat: "280.0" },
          SeedSale { sales_month: "2026-06", title: "1984", net_units: "1", sales_incl_vat: "140.0" },
          SeedSale { sales_month: "2026-07", title: "Thinking, Fast and Slow", net_units: "1", sales_incl_vat: "200.0" }
        ]

        for sale in sales {
          let mk = normalize_title(sale.title)

          let sql = "INSERT INTO sales_history (sales_month, title, net_units, sales_incl_vat, match_key) VALUES (?, ?, ?, ?, ?)"
          let _ = sqlite_exec_p(db, sql, [
            param(sale.sales_month), param(sale.title), param(sale.net_units), param(sale.sales_incl_vat), param(mk)
          ])
        }

        // Seed some overrides
        match sqlite_exec_p(db, "INSERT INTO overrides (match_key, status_override, manual_target, is_hard_to_source, always_reorder) VALUES (?, ?, ?, ?, ?)", [
          param(normalize_title("To Kill a Mockingbird")), param("Core"), param("3"), param("0"), param("1")
        ]) {
          _ => ()
        }
        ()
      } else {
        ()
      }
      ()
    }
  }
}

// Load metric statistics from SQLite
fun get_total_stock_value(db) : float {
  match sqlite_query(db, "SELECT SUM(stock_value) FROM inventory") {
    Err(_) => 0.0,
    Ok(res) => match res.rows {
      [] => 0.0,
      [row, .._] => match row_str(row, 0) {
        None => 0.0,
        Some(s) => match parse_float(s) {
          None => 0.0,
          Some(f) => f
        }
      }
    }
  }
}

fun get_total_items(db) : int {
  match sqlite_query(db, "SELECT SUM(current_stock) FROM inventory") {
    Err(_) => 0,
    Ok(res) => match res.rows {
      [] => 0,
      [row, .._] => match row_int(row, 0) {
        None => 0,
        Some(v) => v
      }
    }
  }
}

fun get_total_titles(db) : int {
  match sqlite_query(db, "SELECT COUNT(*) FROM inventory") {
    Err(_) => 0,
    Ok(res) => match res.rows {
      [] => 0,
      [row, .._] => match row_int(row, 0) {
        None => 0,
        Some(v) => v
      }
    }
  }
}

fun get_sleeper_count(db) : int {
  // Mock Sleeper logic: stock > 0 but 0 sales in sales_history
  let sql = "SELECT COUNT(*) FROM inventory i LEFT JOIN sales_history s ON i.match_key = s.match_key WHERE i.current_stock > 0 AND s.match_key IS NULL"
  match sqlite_query(db, sql) {
    Err(_) => 0,
    Ok(res) => match res.rows {
      [] => 0,
      [row, .._] => match row_int(row, 0) {
        None => 0,
        Some(v) => v
      }
    }
  }
}

fun main() {
  let _ = with_sqlite("elsewhere_inventory.db", (db) => {
    init_db(db)
    seed_data_if_empty(db)

    // Reactive State
    var monthly_budget = 30000.0
    var replenishment_pct = 45.0
    var discovery_pct = 35.0
    var csv_input_inventory = ""
    var csv_input_sales = ""
    var csv_status_message = ""

    gui_window("Elsewhere Booksellers — EBI Inventory System", 1000, 700, () => {
      apply_one_dark_theme()
      // Top Status Bar / Welcome
      gui_text_colored("Elsewhere Booksellers — Inventory System (EBI) Prototype", 0.3, 0.8, 1.0, 1.0)
      gui_separator()

      gui_tab_bar("##main_tabs", () => {
        
        // ----------------- TAB 1: DASHBOARD -----------------
        gui_tab("Dashboard", () => {
          gui_spacing()
          gui_text("Inventory Overview Metrics:")
          gui_separator()

          let total_val = get_total_stock_value(db)
          let total_items = get_total_items(db)
          let total_titles = get_total_titles(db)
          let sleepers = get_sleeper_count(db)

          if gui_begin_table("##metrics_table", 4, 67) {
            gui_table_setup_column("Total Titles")
            gui_table_setup_column("Total Copies")
            gui_table_setup_column("Total Stock Value (SEK)")
            gui_table_setup_column("Sleeper Titles")
            gui_table_headers_row()

            gui_table_next_row()
            gui_table_next_column()
            gui_text(show(total_titles))
            gui_table_next_column()
            gui_text(show(total_items))
            gui_table_next_column()
            gui_text(show(total_val) + " SEK")
            gui_table_next_column()
            gui_text(show(sleepers))

            gui_end_table()
          }

          gui_spacing()
          gui_separator()
          gui_text("Budget Distributions:")
          gui_spacing()

          let rep_allocated = monthly_budget * (replenishment_pct / 100.0)
          let disc_allocated = monthly_budget * (discovery_pct / 100.0)
          let contingency = monthly_budget - rep_allocated - disc_allocated

          gui_text("Monthly Purchasing Budget: " + show(monthly_budget) + " SEK")
          
          gui_text("Replenishment Allocation (" + show(replenishment_pct) + "%): " + show(rep_allocated) + " SEK")
          gui_progress_bar(replenishment_pct / 100.0, "")

          gui_text("Discovery Allocation (" + show(discovery_pct) + "%): " + show(disc_allocated) + " SEK")
          gui_progress_bar(discovery_pct / 100.0, "")

          gui_text("Contingency / Reserve Allocation: " + show(contingency) + " SEK")
          gui_progress_bar(contingency / monthly_budget, "")
        })

        // ----------------- TAB 2: ORDER LIST -----------------
        gui_tab("Order List", () => {
          gui_spacing()
          gui_text("Recommended Replenishment Orders (Calculated on stock levels & overrides)")
          gui_separator()

          // Query items that are out of stock (current_stock <= 0) or flagged as always_reorder
          let sql = "SELECT i.title, i.author, i.current_stock, i.purchase_cost, o.status_override, i.match_key FROM inventory i LEFT JOIN overrides o ON i.match_key = o.match_key WHERE i.current_stock <= 0 OR (o.always_reorder = 1 AND i.current_stock < 2)"

          match sqlite_query(db, sql) {
            Err(e) => gui_text_colored("Database error: " + e.message, 1.0, 0.3, 0.3, 1.0),
            Ok(res) => {
              if res.row_count == 0 {
                gui_text("No pending orders needed. Current inventory targets are satisfied!")
              } else {
                if gui_begin_table("##reorder_table", 6, 67) {
                  gui_table_setup_column("Include")
                  gui_table_setup_column("Book Title")
                  gui_table_setup_column("Author")
                  gui_table_setup_column("Stock")
                  gui_table_setup_column("Cost (SEK)")
                  gui_table_setup_column("Status")
                  gui_table_headers_row()

                  for row in res.rows {
                    gui_table_next_row()
                    gui_table_next_column()
                    
                    let mk = match row_str(row, 5) { None => "", Some(s) => s }
                    let _ = gui_checkbox("##order_" + mk, true)

                    gui_table_next_column()
                    let t_val = match row_str(row, 0) { None => "", Some(s) => s }
                    gui_text(t_val)

                    gui_table_next_column()
                    let a_val = match row_str(row, 1) { None => "Unknown", Some(s) => s }
                    gui_text(a_val)

                    gui_table_next_column()
                    let s_val = match row_int(row, 2) { None => 0, Some(v) => v }
                    gui_text(show(s_val))

                    gui_table_next_column()
                    let c_val = match row_str(row, 3) { None => "0.00", Some(s) => s }
                    gui_text(c_val + " SEK")

                    gui_table_next_column()
                    let st_val = match row_str(row, 4) { None => "Standard", Some(s) => s }
                    gui_text(st_val)
                  }

                  gui_end_table()
                }
              }
            }
          }
        })

        // ----------------- TAB 3: SLEEPER REVIEW -----------------
        gui_tab("Sleeper Review", () => {
          gui_spacing()
          gui_text("Sleeper Titles (Stock present, but no recent monthly sales detected)")
          gui_separator()

          // Query stock with zero sales
          let sql = "SELECT i.title, i.author, i.current_stock, i.first_stocked_date, o.status_override, i.match_key FROM inventory i LEFT JOIN sales_history s ON i.match_key = s.match_key LEFT JOIN overrides o ON i.match_key = o.match_key WHERE i.current_stock > 0 AND s.match_key IS NULL"

          match sqlite_query(db, sql) {
            Err(e) => gui_text_colored("Database error: " + e.message, 1.0, 0.3, 0.3, 1.0),
            Ok(res) => {
              if res.row_count == 0 {
                gui_text("No sleeper titles detected. All active inventory has positive sales!")
              } else {
                if gui_begin_table("##sleeper_table", 5, 67) {
                  gui_table_setup_column("Book Title")
                  gui_table_setup_column("Current Stock")
                  gui_table_setup_column("First Stocked")
                  gui_table_setup_column("Current Override Status")
                  gui_table_setup_column("Actions / Update Status")
                  gui_table_headers_row()

                  for row in res.rows {
                    gui_table_next_row()
                    gui_table_next_column()
                    let t_val = match row_str(row, 0) { None => "", Some(s) => s }
                    gui_text(t_val)

                    gui_table_next_column()
                    let s_val = match row_int(row, 2) { None => 0, Some(v) => v }
                    gui_text(show(s_val))

                    gui_table_next_column()
                    let f_val = match row_str(row, 3) { None => "-", Some(s) => s }
                    gui_text(f_val)

                    gui_table_next_column()
                    let curr_override = match row_str(row, 4) { None => "None", Some(s) => s }
                    gui_text(curr_override)

                    gui_table_next_column()
                    let mk = match row_str(row, 5) { None => "", Some(s) => s }
                    // We render a select combo
                    let combo_items = "No Action\nMerchandise\nDiscount\nDo Not Reorder\nAlways Reorder"
                    let selected = gui_combo("##action_" + mk, combo_items, 0)
                    if selected > 0 {
                      let new_status = match selected {
                        1 => "Merchandise",
                        2 => "Discount",
                        3 => "Do Not Reorder",
                        4 => "Always Reorder",
                        _ => "None"
                      }
                      let always_reorder_flag = if selected == 4 { "1" } else { "0" }

                      // Persist immediately to overrides SQLite table
                      let _ = sqlite_exec_p(db, "INSERT INTO overrides (match_key, status_override, always_reorder) VALUES (?, ?, ?) ON CONFLICT(match_key) DO UPDATE SET status_override=excluded.status_override, always_reorder=excluded.always_reorder", [
                        param(mk), param(new_status), param(always_reorder_flag)
                      ])
                      ()
                    } else {
                      ()
                    }
                    ()
                  }

                  gui_end_table()
                }
              }
            }
          }
        })

        // ----------------- TAB 4: SETTINGS & IMPORT -----------------
        gui_tab("Settings & Import", () => {
          gui_spacing()
          gui_text("EBI Purchasing & Target Settings:")
          gui_separator()

          // Budget Adjustment sliders
          monthly_budget = gui_slider_float("Monthly Budget (SEK)", 1000.0, 100000.0, monthly_budget)
          replenishment_pct = gui_slider_float("Replenishment Share (%)", 0.0, 100.0, replenishment_pct)
          discovery_pct = gui_slider_float("Discovery Share (%)", 0.0, 100.0, discovery_pct)

          gui_spacing()
          gui_separator()
          gui_text_colored("Load Local Datasets from docs/", 0.3, 0.8, 1.0, 1.0)
          gui_spacing()
          gui_text_wrapped("Directly import actual, clean current inventory and sales history CSV files downloaded from your friend's Google Docs.")
          if gui_button("Import Actual Google Docs CSVs") {
            csv_status_message = import_real_data(db)
          }

          gui_spacing()
          gui_separator()
          gui_text_colored("CSV Data Import Center (Powered by RFC 4180 Parser)", 0.2, 0.8, 0.4, 1.0)
          gui_spacing()

          gui_text("1. Current Inventory CSV Import")
          gui_text_wrapped("Paste comma-separated rows. Expected Headers: title,author,distributor,section,barcode,retail_price,purchase_cost,current_stock,first_stocked_date")
          csv_input_inventory = gui_input_text("##csv_inv", 2048)

          if gui_button("Process Inventory CSV") {
            if csv_input_inventory != "" {
              let t = csv_parse(csv_input_inventory)
              let processed_count = length(t.rows)
              for row in t.rows {
                let title = match str_at(row, 0) { None => "", Some(s) => s }
                if title != "" {
                  let author = match str_at(row, 1) { None => "", Some(s) => s }
                  let distributor = match str_at(row, 2) { None => "", Some(s) => s }
                  let section = match str_at(row, 3) { None => "", Some(s) => s }
                  let barcode = match str_at(row, 4) { None => "", Some(s) => s }
                  let retail_price = match str_at(row, 5) { None => "0.0", Some(s) => s }
                  let purchase_cost = match str_at(row, 6) { None => "0.0", Some(s) => s }
                  let current_stock = match str_at(row, 7) { None => "0", Some(s) => s }
                  let first_stocked_date = match str_at(row, 8) { None => "", Some(s) => s }
                  let mk = normalize_title(title)
                  let stock_val = match parse_float(current_stock) {
                    None => 0.0,
                    Some(st) => match parse_float(purchase_cost) {
                      None => 0.0,
                      Some(co) => st * co
                    }
                  }

                  let sql = "INSERT INTO inventory (title, author, distributor, section, barcode, retail_price, purchase_cost, current_stock, stock_value, first_stocked_date, match_key) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(match_key) DO UPDATE SET current_stock=excluded.current_stock, stock_value=excluded.stock_value, first_stocked_date=excluded.first_stocked_date"
                  
                  let _ = sqlite_exec_p(db, sql, [
                    param(title), param(author), param(distributor), param(section),
                    param(barcode), param(retail_price), param(purchase_cost), param(current_stock),
                    param(show(stock_val)), param(first_stocked_date), param(mk)
                  ])
                  ()
                } else {
                  ()
                }
              }
              csv_status_message = "Successfully processed " + show(processed_count) + " inventory records!"
            }
          }

          gui_spacing()
          gui_text("2. Monthly Sales CSV Append")
          gui_text_wrapped("Paste comma-separated rows. Expected Headers: sales_month,title,net_units,sales_incl_vat")
          csv_input_sales = gui_input_text("##csv_sales", 2048)

          if gui_button("Process Sales CSV") {
            if csv_input_sales != "" {
              let t = csv_parse(csv_input_sales)
              let processed_count = length(t.rows)
              for row in t.rows {
                let m = match str_at(row, 0) { None => "", Some(s) => s }
                let title = match str_at(row, 1) { None => "", Some(s) => s }
                if m != "" && title != "" {
                  let net_units = match str_at(row, 2) { None => "0", Some(s) => s }
                  let sales_incl_vat = match str_at(row, 3) { None => "0.0", Some(s) => s }
                  let mk = normalize_title(title)

                  let sql = "INSERT INTO sales_history (sales_month, title, net_units, sales_incl_vat, match_key) VALUES (?, ?, ?, ?, ?)"
                  let _ = sqlite_exec_p(db, sql, [
                    param(m), param(title), param(net_units), param(sales_incl_vat), param(mk)
                  ])
                  ()
                } else {
                  ()
                }
              }
              csv_status_message = "Successfully appended " + show(processed_count) + " monthly sales records!"
            }
          }

          if csv_status_message != "" {
            gui_spacing()
            gui_text_colored(csv_status_message, 0.2, 0.9, 0.2, 1.0)
          }
        })
      })
    })
  })
}
