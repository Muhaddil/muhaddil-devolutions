# Muhaddil Devolutions

A powerful and flexible Devolutions (Returns) System for FiveM, supporting ESX and QBCore. This script allows administrators to manage player purchases, return items (vehicles, custom plates, phone verifications) and more through an intuitive NUI panel.

## 🚀 Features

- **Multi-Framework Support:** Automatic detection or manual configuration for ESX and QBCore.
- **Standalone Mode:** Can run without needing for the in-game store from Pickle Mods https://picklemods.com/package/6664832.
- **Admin Panel:** A clean NUI interface to manage players and products.
- **Product Management:** Create and manage products with categories, models, and custom icons.
- **Return System:**
  - **Vehicles:** Automatically generates plates and adds vehicles to player garages.
  - **Custom Plates:** Update vehicle plates directly.
  - **Phone Verification:** Integration with `lb-phone` for social media verification.
  - **Offline Support:** Search and manage items for players who are not currently online.
- **Discord Webhooks:** Comprehensive logging for every administrative action (adding items, returning items, deleting items).
- **Search Functionality:** Easily find players by their Discord ID or license.

## 📋 Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- (Optional) [lb-phone](https://github.com/lb-phone) for verification features.
- (Optional) [Pickle Mods In-Game Store](https://picklemods.com/package/6664832) for currency usage and easier setup.

## 🛠️ Installation

1. **Download & Extract:** Place the `muhaddil-devolutions` folder into your server's `resources` directory.
2. **Database Setup:** Import the provided `SQL.sql` file into your database.
3. **Configuration:**
   - Open `config.lua` and set your preferred framework (`auto`, `esx`, or `qb`).
   - Configure `Config.AllowedGroups` to define who can access the panel.
   - Set `Config.StandaloneMode` to `true` if you are not using a supported framework.
4. **Webhooks:**
   - Open `server/main.lua` and replace the placeholder URLs at the top of the file with your Discord webhook URLs:
     ```lua
     local sendAddItemWebhook = "YOUR_WEBHOOK_HERE"
     local returnItemWebhook = "YOUR_WEBHOOK_HERE"
     local coinsAddWebhook = "YOUR_WEBHOOK_HERE"
     local coinsRemoveWebhook = "YOUR_WEBHOOK_HERE"
     local deleteItemWebhook = "YOUR_WEBHOOK_HERE"
     ```
5. **Start Resource:** Add `ensure muhaddil-devolutions` to your `server.cfg`.

## 🎮 Usage

### Admin Command

Open the administration panel using the following command:

```
/storepanel
```

_Note: You must have the permissions defined in `config.lua` or ACE permissions to use this command._
