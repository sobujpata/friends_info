# Implementation Plan - Modify Friends Table Schema

Modify the `friends` table and the associated Flutter components to include new fields: `trade`, `blood_gp`, `district`, `upazila`, and `present_address`.

## User Review Required

> [!IMPORTANT]
> **Database Migration**: Since the table schema is changing, the existing local database needs to be updated. I will increment the database version to `2`. This will trigger a schema update, but to ensure consistency, I recommend the user to clear the app data or uninstall/reinstall the app on the emulator if they encounter issues with old records.

## Proposed Changes

### Data Model

#### [MODIFY] [friend.dart](file:///D:/Android-app/friends_info/lib/models/friend.dart)
- Update `Friend` class to include: `trade`, `bloodGp`, `district`, `upazila`, `presentAddress`.
- Update `toMap()`, `fromMap()`, and `copyWith()`.

### Database Service

#### [MODIFY] [db_service.dart](file:///D:/Android-app/friends_info/lib/services/db_service.dart)
- Increment database version to `2`.
- Update `CREATE TABLE` statement in `onCreate`.
- Implement `onUpgrade` to handle the transition (or simply recreate the table for simplicity in this dev stage).
- Update search logic in `list()` to include `trade`, `district`, etc.

### User Interface

#### [MODIFY] [friend_form_screen.dart](file:///D:/Android-app/friends_info/lib/screens/friend_form_screen.dart)
- Add new `TextEditingController`s for the new fields.
- Add `TextFormField`s to the form layout.
- Update validation for required fields (`name`, `personnel_no`, `phone`).
- Update `_save()` logic to map new fields to the `Friend` model.

#### [MODIFY] [friend_detail_screen.dart](file:///D:/Android-app/friends_info/lib/screens/friend_detail_screen.dart)
- Update layout to display the new information.

#### [MODIFY] [friend_tile.dart](file:///D:/Android-app/friends_info/lib/widgets/friend_tile.dart)
- Optionally update the tile to show `trade` or another key field.

### Services

#### [MODIFY] [backup_service.dart](file:///D:/Android-app/friends_info/lib/services/backup_service.dart)
- Ensure the backup/restore logic handles the new fields correctly (it should, as it uses `toMap`/`fromMap`).

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure basic app startup still works.

### Manual Verification
1. Open the app and ensure existing records (if any) are handled.
2. Open "Add friend" form.
3. Verify that new fields (`trade`, `blood_gp`, etc.) are present.
4. Fill all fields and save.
5. Verify the friend appears in the list.
6. Open the detail screen and verify all new fields are displayed.
7. Edit the friend and verify changes persist.
