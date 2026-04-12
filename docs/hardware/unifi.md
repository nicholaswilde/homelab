---
tags:
  - hardware
  - unifi
---
# :simple-ubiquiti: UniFi

I have a UniFi network setup with the following devices.

## :gear: Devices

| Name | Model | Type | IP | MAC | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Switch | US24P250 | usw | 192.168.1.164 | f0:9f:c2:0b:39:ad | online |
| Family Room Switch | USMINI | usw | 192.168.1.79 | 74:83:c2:08:6a:b0 | online |
| Living Room Switch | USMINI | usw | 192.168.1.233 | 74:83:c2:0c:49:bf | online |
| Family Room AP | UAL6 | uap | 192.168.1.24 | 24:5a:4c:1a:aa:dc | online |
| Bedroom Switch | USMINI | usw | 192.168.1.249 | 74:83:c2:0c:49:ba | online |
| Man Cave AP | UAP6MP | uap | 192.168.1.113 | 70:a7:41:6a:2b:15 | online |
| Man Cave Switch | USMINI | usw | 192.168.1.68 | 78:45:58:47:c2:70 | online |
| LTE | ULTE | uap | 192.168.1.153 | f4:92:bf:6c:95:ec | offline |
| UCG | UCG-Max | ugw | 68.111.82.103 | fc:ec:da:46:02:9e | online |
| Kitchen AP | U6IW | uap | 192.168.1.130 | 70:a7:41:af:30:43 | online |
| Attic Switch | USMINI | usw | 192.168.1.23 | f4:92:bf:a3:fa:81 | online |

## :camera: Cameras

| Name | IP | MAC | Status |
| :--- | :--- | :--- | :--- |
| Guest Room Protect | 192.168.1.199 | 18:b4:30:aa:1d:d0 | online |
| Upstairs Hallway Protect | 192.168.1.214 | 18:b4:30:aa:48:93 | online |
| Master Bedroom Protect | 192.168.1.208 | 18:b4:30:aa:47:e7 | online |

## :control_knobs: Controllers

| Name | IP | MAC | Status |
| :--- | :--- | :--- | :--- |
| CloudKey | 192.168.1.148 | 18:e8:29:4f:60:a9 | online |

## :simple-ubiquiti: Changing the Default Site in UniFi

While the UniFi UI does not allow you to change which site is designated as "default," it can be achieved by updating the underlying MongoDB database. This is useful if you need to delete the original default site.

!!! warning "Backup Required"
    Before proceeding, take a full backup of your UniFi Controller settings. Direct database manipulation carries risk.

### :material-console: Procedure

#### 1. Access the Database
SSH into your UniFi Controller (e.g., your CloudKey at `192.168.1.148`) and connect to the local MongoDB instance:

```shell
mongo --port 27117
```

Switch to the UniFi database:

```javascript
use ace
```

#### 2. Identify Site ObjectIDs

List all sites to find the `_id` for both the current "default" site and the one you wish to promote:

```javascript
db.site.find()
```

  * **[ID_1]**: The `_id` of the site where `"name": "default"`.
  * **[ID_2]**: The `_id` of your target site (e.g., "Main Site").

#### 3. Swap Default Attributes

Remove the default flags from the old site and assign them to the new site:

Remove default flags from current site

```javascript
db.site.update({ _id: ObjectId("[ID_1]") }, { $unset: { attr_hidden_id: "", attr_no_delete: "" } })
```

Assign default flags to new site

```
db.site.update({ _id: ObjectId("[ID_2]") }, { $set: { attr_hidden_id: "default", attr_no_delete: true } })
```

#### 4. Apply Changes

Exit the Mongo shell and restart the UniFi service to apply the changes:

```shell
exit
systemctl restart unifi
```

## :link: References

  - [Ubiquiti Community Wiki - Changing Default Site](https://ubntwiki.com/guides/changing_the_default_site_in_unifi)
  - [UniFi Hardware Documentation](https://www.google.com/search?q=unifi.md)
  - <https://ui.com/>
