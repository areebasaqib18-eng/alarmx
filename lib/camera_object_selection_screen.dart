
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraObjectSelectionScreen extends StatefulWidget {
  const CameraObjectSelectionScreen({super.key});

  @override
  State<CameraObjectSelectionScreen> createState() =>
      _CameraObjectSelectionScreenState();
}

class _CameraObjectSelectionScreenState
    extends State<CameraObjectSelectionScreen> {
  static const String storageKey = 'alarmx_camera_objects';

  final List<String> objects = [
    'Bottle',
    'Shoes',
    'Toothbrush',
    'Book',
    'Keys',
    'Cup',
    'Phone',
    'Watch',
    'Glasses',
    'Wallet',
    'Bag',
    'Pillow',
    'Chair',
    'Remote',
    'Laptop',
    'Mouse',
    'Keyboard',
    'Spoon',
    'Plate',
    'Toothpaste',
    'Comb',
    'Towel',
    'Umbrella',
    'Ball',
    'Pen',
    'Notebook',
    'Bottle Cap',
    'Headphones',
    'Soap',
    'Teddy Bear',
    'Tree',
'Plant',
'Car',
'Bike',
'Road',
  ];

  final Set<String> selectedObjects = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedObjects();
  }

  Future<void> _loadSavedObjects() async {
    final prefs = await SharedPreferences.getInstance();
    final savedObjects = prefs.getStringList(storageKey) ?? [];

    if (!mounted) return;

    setState(() {
      selectedObjects.addAll(savedObjects);
      isLoading = false;
    });
  }

  Future<void> _saveAndContinue() async {
    if (selectedObjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one object.'),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final result = selectedObjects.toList();

    await prefs.setStringList(storageKey, result);

    if (!mounted) return;

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        foregroundColor: Colors.white,
        title: const Text('Camera Challenge'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Select the objects you want to use in your '
                    'Camera Challenge. The alarm will randomly choose '
                    'one of your selected objects.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Available Objects',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${selectedObjects.length} selected',
                        style: const TextStyle(color: Color(0xFFABD7E1)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: objects.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final object = objects[index];
                      final isSelected =
                          selectedObjects.contains(object);

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedObjects.remove(object);
                            } else {
                              selectedObjects.add(object);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFABD7E1)
                                : const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFABD7E1)
                                  : Colors.white24,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? const Color(0xFF1C1C1E)
                                    : Colors.white70,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  object,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF1C1C1E)
                                        : Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFABD7E1),
                        foregroundColor: const Color(0xFF1C1C1E),
                      ),
                      child: const Text(
                        'Save Selected Objects',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
