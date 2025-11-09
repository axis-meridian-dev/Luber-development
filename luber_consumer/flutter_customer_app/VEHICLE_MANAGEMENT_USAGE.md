# Vehicle Management - Quick Usage Guide

## How to Use Vehicle Management in the App

### Accessing Vehicle Management

From the Profile screen:
```
Home Screen → Profile Tab → "My Vehicles" → Vehicles List Screen
```

### Adding a New Vehicle

1. Open Vehicles List Screen
2. Tap the blue floating action button "+ Add Vehicle"
3. Fill in required fields:
   - Make (e.g., "Toyota")
   - Model (e.g., "Camry")
   - Year (e.g., "2024")
   - Select vehicle type by tapping a chip
   - Select oil type from dropdown
4. Optionally add:
   - License Plate
   - VIN (must be 17 characters)
   - Oil Capacity (in quarts)
5. Check "Set as default vehicle" if desired
6. Tap "Add Vehicle" button
7. Green success message appears
8. Automatically returns to vehicle list

### Editing a Vehicle

1. From Vehicles List Screen, tap any vehicle card
2. Edit Vehicle Screen opens with pre-filled data
3. Modify any fields as needed
4. Tap "Save Changes" button
5. Green success message appears
6. Automatically returns to vehicle list

### Deleting a Vehicle

**Method 1: Swipe to Delete**
1. From Vehicles List Screen
2. Swipe vehicle card from right to left
3. Red delete background appears
4. Confirmation dialog appears
5. Tap "Delete" to confirm or "Cancel" to abort
6. Vehicle removed from list

**Method 2: Delete from Edit Screen**
1. Tap vehicle card to open Edit Screen
2. Tap "Delete Vehicle" button at bottom
3. Confirmation dialog appears
4. Tap "Delete" to confirm
5. Returns to vehicle list

**Alternative: Delete Icon in Edit Screen**
1. Tap vehicle card to open Edit Screen
2. Tap trash icon in app bar
3. Confirmation dialog appears
4. Tap "Delete" to confirm

### Understanding Vehicle Display

Each vehicle card shows:
- **Vehicle Icon**: Type-specific icon (car, SUV, truck, etc.)
- **Vehicle Name**: Year + Make + Model (e.g., "2024 Toyota Camry")
- **Default Badge**: Gold star badge if set as default
- **Vehicle Type Chip**: Visual chip showing type (Sedan, SUV, etc.)
- **Oil Type Chip**: Visual chip showing recommended oil
- **License Plate**: If available, shown below chips
- **Chevron Icon**: Indicates card is tappable

### Default Vehicle

- Only one vehicle can be default at a time
- Default vehicle is used for quick bookings
- Shown with gold "Default" badge with star icon
- Set during add/edit by checking "Set as default vehicle"
- Setting a new default automatically removes previous default

### Vehicle Types Available

1. **Sedan** - Standard passenger car
2. **SUV** - Sport utility vehicle
3. **Truck** - Pickup truck
4. **Sports Car** - High-performance vehicle
5. **Hybrid** - Hybrid electric vehicle
6. **Electric** - Fully electric vehicle

### Oil Types Available

1. **Conventional** - Standard motor oil
2. **Synthetic Blend** - Partial synthetic oil
3. **Full Synthetic** - Premium synthetic oil
4. **High Mileage** - For vehicles with 75k+ miles

### Form Validation

**Make & Model**
- Required fields
- Cannot be empty
- Automatically capitalizes first letter

**Year**
- Required field
- Must be 4 digits
- Must be between 1900 and current year + 1
- Only numbers allowed

**License Plate**
- Optional
- Automatically converts to uppercase

**VIN**
- Optional
- Must be exactly 17 characters if provided
- Automatically converts to uppercase

**Oil Capacity**
- Optional
- Must be between 0 and 20 quarts
- Allows decimal values (e.g., 5.5)

### Loading States

While API calls are in progress:
- **Add Screen**: "Add Vehicle" button shows spinner
- **Edit Screen**: "Save Changes" button shows spinner
- **Delete**: "Delete Vehicle" button shows spinner
- **List Screen**: Full-screen spinner while fetching

### Error Handling

**Network Errors**
- Red SnackBar appears at bottom
- Error message displayed
- Can retry by:
  - Pulling down to refresh (list screen)
  - Tapping "Retry" button (error state)
  - Resubmitting form (add/edit screens)

**Validation Errors**
- Red text appears below invalid field
- Form cannot be submitted until fixed
- Errors clear when field is corrected

### Success Feedback

All successful operations show green SnackBar:
- "Vehicle added successfully"
- "Vehicle updated successfully"
- "Vehicle deleted successfully"

### Empty State

When no vehicles exist:
- Large car icon (gray)
- "No vehicles yet" message
- "Add your first vehicle to get started" subtitle
- Floating action button available to add first vehicle

### Refresh Vehicle List

Pull down on the list to refresh:
- Swipe down gesture
- Circular progress indicator appears
- List reloads from API
- Updates all vehicle data

## Tips & Best Practices

1. **Always set a default vehicle** for faster booking
2. **Include VIN** for accurate service records
3. **Add license plate** for technician verification
4. **Specify oil capacity** if known for better service
5. **Keep vehicle info updated** after changes

## Troubleshooting

**"Not authenticated" error**
- Sign out and sign back in
- Check network connection

**"Failed to fetch vehicles" error**
- Pull down to refresh
- Check network connection
- Verify API is running

**"Failed to add/update vehicle" error**
- Check all required fields
- Verify year is valid
- Ensure VIN is 17 characters (if provided)
- Check network connection

**Vehicle not appearing after add**
- Pull down to refresh list
- Go back and return to screen

**Can't delete last vehicle**
- At least one vehicle may be required
- Contact support if needed

## Code Integration

### Importing Screens

```dart
// Import in your navigation code
import 'package:luber_customer/screens/vehicle/vehicles_screen.dart';
import 'package:luber_customer/screens/vehicle/add_vehicle_screen.dart';
import 'package:luber_customer/screens/vehicle/edit_vehicle_screen.dart';
```

### Navigation Examples

```dart
// Navigate to vehicles list
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const VehiclesScreen(),
  ),
);

// Navigate to add vehicle
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const AddVehicleScreen(),
  ),
);

// Navigate to edit vehicle
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => EditVehicleScreen(vehicle: vehicleModel),
  ),
);
```

### Using Vehicle Provider

```dart
// Get vehicles list
final vehicleProvider = context.watch<VehicleProvider>();
final vehicles = vehicleProvider.vehicles;

// Get default vehicle
final defaultVehicle = vehicleProvider.defaultVehicle;

// Fetch vehicles
await context.read<VehicleProvider>().fetchVehicles();

// Add vehicle
final success = await context.read<VehicleProvider>().addVehicle(
  make: 'Toyota',
  model: 'Camry',
  year: 2024,
  vehicleType: 'sedan',
  recommendedOilType: 'full_synthetic',
);

// Update vehicle
final success = await context.read<VehicleProvider>().updateVehicle(
  vehicleId: vehicle.id,
  make: 'Honda',
  model: 'Accord',
  year: 2024,
  vehicleType: 'sedan',
  recommendedOilType: 'synthetic_blend',
);

// Delete vehicle
final success = await context.read<VehicleProvider>().deleteVehicle(vehicleId);
```

## API Endpoints Used

All endpoints require authentication via Bearer token:

```
GET    /api/vehicles           - Fetch all vehicles
POST   /api/vehicles           - Create new vehicle
PATCH  /api/vehicles/[id]      - Update vehicle
DELETE /api/vehicles/[id]      - Delete vehicle
```

## Related Features

- **Booking Flow**: Select vehicle during booking
- **Service History**: View past services per vehicle
- **Payment Methods**: Link payment to vehicle (future)

## Support

For issues or questions:
- Check network connectivity first
- Verify API configuration in `lib/config/constants.dart`
- Check Supabase authentication status
- Review error messages in SnackBars
- Pull to refresh and retry operations
