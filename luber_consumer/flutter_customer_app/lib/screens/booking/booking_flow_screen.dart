import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import 'steps/vehicle_step.dart';
import 'steps/address_step.dart';
import 'steps/service_step.dart';
import 'steps/schedule_step.dart';
import 'steps/confirmation_step.dart';

/// Booking Flow Screen
///
/// A multi-step wizard for booking an oil change service:
/// 1. Vehicle Selection - Choose vehicle from saved list or add new
/// 2. Address Selection - Select service location from saved addresses
/// 3. Service Selection - Choose oil type with dynamic pricing
/// 4. Schedule Selection - Pick date and time slot
/// 5. Confirmation - Review booking and confirm payment
class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final List<_StepInfo> _steps = const [
    _StepInfo(
      title: 'Vehicle',
      description: 'Select your vehicle',
      icon: Icons.directions_car,
    ),
    _StepInfo(
      title: 'Location',
      description: 'Choose service location',
      icon: Icons.location_on,
    ),
    _StepInfo(
      title: 'Service',
      description: 'Select oil type',
      icon: Icons.local_gas_station,
    ),
    _StepInfo(
      title: 'Schedule',
      description: 'Pick date & time',
      icon: Icons.calendar_today,
    ),
    _StepInfo(
      title: 'Confirm',
      description: 'Review and pay',
      icon: Icons.check_circle,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentStep = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _steps.length;

    return ChangeNotifierProvider(
      create: (_) => BookingProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Book Service'),
          backgroundColor: const Color(0xFF0070F3),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Progress Header
            Container(
              color: const Color(0xFF0070F3),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of ${_steps.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _steps[_currentStep].title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _steps[_currentStep].description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Step indicators row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_steps.length, (index) {
                  final isCompleted = index < _currentStep;
                  final isCurrent = index == _currentStep;
                  final step = _steps[index];

                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCompleted || isCurrent
                                ? const Color(0xFF0070F3)
                                : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check : step.icon,
                            size: 18,
                            color: isCompleted || isCurrent
                                ? Colors.white
                                : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                            color: isCompleted || isCurrent
                                ? const Color(0xFF0070F3)
                                : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            // Page view with steps
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe navigation
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: VehicleStep(
                      onNext: _nextStep,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: AddressStep(
                      onNext: _nextStep,
                      onBack: _previousStep,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ServiceStep(
                      onNext: _nextStep,
                      onBack: _previousStep,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ScheduleStep(
                      onNext: _nextStep,
                      onBack: _previousStep,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ConfirmationStep(
                      onBack: _previousStep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step information model
class _StepInfo {
  final String title;
  final String description;
  final IconData icon;

  const _StepInfo({
    required this.title,
    required this.description,
    required this.icon,
  });
}
