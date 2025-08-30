// import 'package:clipper/Widgets/collection_card.dart';
// import 'package:clipper/collections.dart';
// import 'package:clipper/create_new_collection.dart';
// import 'package:clipper/models.dart';
// import 'package:clipper/service.dart';
// import 'package:flutter/material.dart';

// class SavedCollectionScreen extends StatefulWidget {
//   const SavedCollectionScreen({Key? key}) : super(key: key);

//   @override
//   State<SavedCollectionScreen> createState() => _SavedCollectionScreenState();
// }

// class _SavedCollectionScreenState extends State<SavedCollectionScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   List<CollectionModel> _allCollections = [];
//   List<CollectionModel> _filteredCollections = [];
//   bool isLoading = true;
//   String _searchQuery = '';

//   @override
//   void initState() {
//     super.initState();
//     loadData();
//     _searchController.addListener(_onSearchChanged);
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _onSearchChanged() {
//     setState(() {
//       _searchQuery = _searchController.text.toLowerCase();
//       _applySearch();
//     });
//   }

//   void _applySearch() {
//     if (_searchQuery.isEmpty) {
//       setState(() {
//         _filteredCollections = _allCollections;
//       });
//     } else {
//       setState(() {
//         _filteredCollections = _allCollections
//             .where(
//               (collection) =>
//                   collection.name.toLowerCase().contains(_searchQuery),
//             )
//             .toList();
//       });
//     }
//   }

//   void showCreateCollectionDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => CreateCollectionDialog(),
//     );
//   }

//   Future<void> loadData() async {
//     try {
//       // Load collections
//       final collectionsData = await FirebaseService.getLatestCollections();

//       setState(() {
//         _allCollections = collectionsData;
//         _filteredCollections = collectionsData;
//         isLoading = false;
//       });
//     } catch (e) {
//       print('Error loading data: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> _refreshData() async {
//     await loadData();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header with title and new button
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Row(
//                 children: [
//                   const Text(
//                     'Collections',
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const Spacer(),
//                   TextButton(
//                     onPressed: () {
//                       showCreateCollectionDialog(context);
//                     },
//                     style: TextButton.styleFrom(
//                       backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.1),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 8,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'New',
//                       style: TextStyle(
//                         color: Color(0xFF7C4DFF),
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Search Bar
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: TextField(
//                   controller: _searchController,
//                   decoration: const InputDecoration(
//                     hintText: 'Search collections...',
//                     hintStyle: TextStyle(color: Colors.grey),
//                     prefixIcon: Icon(Icons.search, color: Colors.grey),
//                     border: InputBorder.none,
//                     contentPadding: EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 12,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Collections Content
//             Expanded(
//               child: isLoading
//                   ? const Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CircularProgressIndicator(
//                             color: Color(0xFF7C4DFF),
//                             strokeWidth: 3,
//                           ),
//                           SizedBox(height: 16),
//                           Text(
//                             'Loading collections...',
//                             style: TextStyle(color: Colors.grey, fontSize: 16),
//                           ),
//                         ],
//                       ),
//                     )
//                   : _filteredCollections.isEmpty
//                   ? _buildEmptyState()
//                   : RefreshIndicator(
//                       onRefresh: _refreshData,
//                       color: const Color(0xFF7C4DFF),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 20),
//                         child: GridView.builder(
//                           physics: const AlwaysScrollableScrollPhysics(),
//                           gridDelegate:
//                               const SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount: 2,
//                                 crossAxisSpacing: 16,
//                                 mainAxisSpacing: 16,
//                                 childAspectRatio: 1.2,
//                               ),
//                           itemCount: _filteredCollections.length,
//                           itemBuilder: (context, index) {
//                             final collection = _filteredCollections[index];
//                             return CollectionCard(
//                               collection: collection,
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   PageRouteBuilder(
//                                     pageBuilder:
//                                         (
//                                           context,
//                                           animation,
//                                           secondaryAnimation,
//                                         ) => CollectionScreen(
//                                           collectionId: collection.id,
//                                           collectionName: collection.name,
//                                         ),
//                                     transitionsBuilder:
//                                         (
//                                           context,
//                                           animation,
//                                           secondaryAnimation,
//                                           child,
//                                         ) {
//                                           return SlideTransition(
//                                             position:
//                                                 Tween<Offset>(
//                                                   begin: const Offset(1, 0),
//                                                   end: Offset.zero,
//                                                 ).animate(
//                                                   CurvedAnimation(
//                                                     parent: animation,
//                                                     curve: Curves.easeInOut,
//                                                   ),
//                                                 ),
//                                             child: child,
//                                           );
//                                         },
//                                   ),
//                                 );
//                               },
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//             ),

//             SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 120,
//             height: 120,
//             decoration: BoxDecoration(
//               color: const Color(0xFF7C4DFF).withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.collections_bookmark_outlined,
//               size: 60,
//               color: Color(0xFF7C4DFF),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             _searchQuery.isNotEmpty
//                 ? 'No collections found for "$_searchQuery"'
//                 : 'No collections yet',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _searchQuery.isNotEmpty
//                 ? 'Try searching with different keywords'
//                 : 'Create your first collection to get started',
//             style: TextStyle(fontSize: 14, color: Colors.grey[500]),
//             textAlign: TextAlign.center,
//           ),
//           if (_searchQuery.isEmpty) ...[
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () => showCreateCollectionDialog(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF7C4DFF),
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 2,
//               ),
//               icon: const Icon(Icons.add_rounded, size: 20),
//               label: const Text(
//                 'Create Collection',
//                 style: TextStyle(fontWeight: FontWeight.w600),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

import 'package:clipper/Widgets/collection_card.dart';
import 'package:clipper/collections.dart';
import 'package:clipper/create_new_collection.dart';
import 'package:clipper/models.dart';
import 'package:clipper/service.dart';
import 'package:flutter/material.dart';

class SavedCollectionScreen extends StatefulWidget {
  const SavedCollectionScreen({Key? key}) : super(key: key);

  @override
  State<SavedCollectionScreen> createState() => _SavedCollectionScreenState();
}

class _SavedCollectionScreenState extends State<SavedCollectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CollectionModel> _allCollections = [];
  List<CollectionModel> _filteredCollections = [];
  bool isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applySearch();
    });
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredCollections = _allCollections;
      });
    } else {
      setState(() {
        _filteredCollections = _allCollections
            .where(
              (collection) =>
                  collection.name.toLowerCase().contains(_searchQuery),
            )
            .toList();
      });
    }
  }

  void showCreateCollectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateCollectionDialog(),
    );
  }

  Future<void> loadData() async {
    try {
      // Load collections
      final collectionsData = await FirebaseService.getLatestCollections();

      setState(() {
        _allCollections = collectionsData;
        _filteredCollections = collectionsData;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and new button - Enhanced for dark theme
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Collections',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      showCreateCollectionDialog(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(
                        color: Color(0xFF7C4DFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar - Enhanced for dark theme
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: isDarkMode
                      ? Border.all(color: Colors.grey[700]!, width: 1)
                      : null,
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search collections...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Collections Content
            Expanded(
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF7C4DFF),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading collections...',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredCollections.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      color: const Color(0xFF7C4DFF),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.2,
                              ),
                          itemCount: _filteredCollections.length,
                          itemBuilder: (context, index) {
                            final collection = _filteredCollections[index];
                            return CollectionCard(
                              collection: collection,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => CollectionScreen(
                                          collectionId: collection.id,
                                          collectionName: collection.name,
                                        ),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return SlideTransition(
                                            position:
                                                Tween<Offset>(
                                                  begin: const Offset(1, 0),
                                                  end: Offset.zero,
                                                ).animate(
                                                  CurvedAnimation(
                                                    parent: animation,
                                                    curve: Curves.easeInOut,
                                                  ),
                                                ),
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.collections_bookmark_outlined,
              size: 60,
              color: Color(0xFF7C4DFF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No collections found for "$_searchQuery"'
                : 'No collections yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try searching with different keywords'
                : 'Create your first collection to get started',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => showCreateCollectionDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Create Collection',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
