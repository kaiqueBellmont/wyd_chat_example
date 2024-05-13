import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:labalaba/cache/local_cache.dart';
import 'package:labalaba/data/datasources/datasource_contract.dart';
import 'package:labalaba/data/datasources/sqflite_datasource.dart';
import 'package:labalaba/data/factories/db_factory.dart';
import 'package:labalaba/data/services/image_uploader.dart';
import 'package:labalaba/models/chat.dart';
import 'package:labalaba/states_management/home/chats_cubit.dart';
import 'package:labalaba/states_management/home/group_cubit.dart';
import 'package:labalaba/states_management/home/home_cubit.dart';
import 'package:labalaba/states_management/message/message_bloc.dart';
import 'package:labalaba/states_management/message_group/message_group_bloc.dart';
import 'package:labalaba/states_management/message_thread/message_thread_cubit.dart';
import 'package:labalaba/states_management/onboarding/onboarding_cubit.dart';
import 'package:labalaba/states_management/onboarding/profile_image_cubit.dart';
import 'package:labalaba/states_management/receipt/receipt_bloc.dart';
import 'package:labalaba/states_management/typing/typing_notification_bloc.dart';
import 'package:labalaba/ui/pages/home/home.dart';
import 'package:labalaba/ui/pages/home/home_router.dart';
import 'package:labalaba/ui/pages/message_thread/message_thread.dart';
import 'package:labalaba/ui/pages/onboarding/onboarding.dart';
import 'package:labalaba/ui/pages/onboarding/onboarding_router.dart';
import 'package:labalaba/ui/widgets/home/create_group.dart';
import 'package:labalaba/viewmodels/chat_view_model.dart';
import 'package:labalaba/viewmodels/chats_view_model.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class CompositionRoot {
  static late RethinkDb _r;
  static late Connection _connection;
  static late IUserService _userService;
  static late Database _db;
  static late IMessageService _messageService;
  static late IDatasource _datasource;
  static late ILocalCache _localCache;
  static late MessageBloc _messageBloc;
  static late ITypingNotification _typingNotification;
  static late TypingNotificationBloc _typingNotificationBloc;
  static late ChatsCubit _chatsCubit;
  static late IGroupService _groupService;
  static late MessageGroupBloc _messageGroupBloc;
  static late IHomeRouter _homeRouter;
  static late ChatsViewModel _viewModel;

  static configure() async {
    _r = RethinkDb();
    _connection = await _r.connect(host: '172.17.0.2', port: 28015);
    _userService = UserService(_r, _connection);
    _messageService = MessageService(_r, _connection);
    _typingNotification = TypingNotification(_r, _connection, _userService);
    _db = await LocalDatabaseFactory().createDatabase();
    _datasource = SqfliteDatasource(_db);
    final sp = await SharedPreferences.getInstance();
    _localCache = LocalCache(sp);
    _messageBloc = MessageBloc(_messageService);
    _typingNotificationBloc = TypingNotificationBloc(_typingNotification);
    _viewModel = ChatsViewModel(_datasource, _userService);
    _chatsCubit = ChatsCubit(_viewModel);

    _groupService = MessageGroupService(_r, _connection);
    _messageGroupBloc = MessageGroupBloc(_groupService);

    _homeRouter =
        HomeRouter(showMessageThread: composeMessageThreadUi, showCreatedGroup: composeGroupUi);

    _db.delete('chats');
    _db.delete('messages');
  }

  static Widget start() {
    final user = _localCache.fetch('USER');
    return user.isEmpty ? composeOnboardingUi() : composeHomeUi(User.fromJson(user));
  }

  static Widget composeOnboardingUi() {
    ImageUploader imageUploader = ImageUploader('http://10.0.2.2:3000/');

    OnboardingCubit onboardingCubit = OnboardingCubit(_userService, imageUploader, _localCache);
    ProfileImageCubit imageCubit = ProfileImageCubit();
    IOnboardingRouter router = OnboardingRouter(composeHomeUi);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (BuildContext context) => onboardingCubit),
        BlocProvider(create: (BuildContext context) => imageCubit),
      ],
      child: Onboarding(router),
    );
  }

  static Widget composeHomeUi(User me) {
    HomeCubit homeCubit = HomeCubit(_userService, _localCache);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (BuildContext context) => homeCubit),
        BlocProvider(
          create: (BuildContext context) => _messageBloc,
        ),
        BlocProvider(create: (BuildContext context) => _typingNotificationBloc),
        BlocProvider(
          create: (BuildContext context) => _chatsCubit,
        ),
        BlocProvider(create: (BuildContext context) => _messageGroupBloc)
      ],
      child: Home(_viewModel, _homeRouter, me),
    );
  }

  static Widget composeMessageThreadUi(List<User> receivers, User me, Chat chat) {
    ChatViewModel viewModel = ChatViewModel(_datasource);
    MessageThreadCubit messageThreadCubit = MessageThreadCubit(viewModel);
    IReceiptService receiptService = ReceiptService(_r, _connection);
    ReceiptBloc receiptBloc = ReceiptBloc(receiptService);

    return MultiBlocProvider(
        providers: [
          BlocProvider(create: (BuildContext context) => messageThreadCubit),
          BlocProvider(create: (BuildContext context) => receiptBloc)
        ],
        child:
            MessageThread(receivers, me, _messageBloc, _chatsCubit, _typingNotificationBloc, chat));
  }

  static Widget composeGroupUi(List<User> activeUsers, User me) {
    GroupCubit groupCubit = GroupCubit();
    MessageGroupBloc messageGroupBloc = MessageGroupBloc(_groupService);

    return MultiBlocProvider(providers: [
      BlocProvider(create: (BuildContext context) => groupCubit),
      BlocProvider(create: (BuildContext context) => messageGroupBloc),
    ], child: CreateGroup(activeUsers, me, _chatsCubit, _homeRouter));
  }
}
