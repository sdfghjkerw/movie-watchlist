import 'package:flutter/widgets.dart';

class AppLanguage extends InheritedWidget {
  const AppLanguage({super.key, required this.language, required super.child});
  final String language;
  @override
  bool updateShouldNotify(AppLanguage oldWidget) =>
      language != oldWidget.language;
}

extension AppTranslation on String {
  String tr(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguage>()?.language ==
          'en'
      ? translations[this] ?? this
      : this;
}

const translations = <String, String>{
  'Фото профиля': 'Profile photo',
  'Твоя история — фильм за фильмом': 'Your story, one film at a time',
  'Оценки и впечатления, сохранённые для себя.':
      'Ratings and thoughts, saved just for you.',
  'Найти фильм или впечатление': 'Search films and impressions',
  'Все записи': 'All entries',
  'С отзывом': 'Reviews',
  'Только оценка': 'Rating only',
  'Только оценка · ': 'Rating only · ',
  'Пока нет отзывов': 'No reviews yet',
  'Пока нет оценок без текста': 'No rating-only entries yet',
  'Ничего не найдено': 'Nothing found',
  'Попробуй изменить запрос или очистить поиск.':
      'Try changing your search or clear it.',
  'Поставь оценку или запиши впечатление на странице фильма — оно появится здесь.':
      'Rate a film or write a thought on its page, and it will appear here.',
  'Личные данные': 'Personal details',
  'Выбрать фото': 'Choose photo',
  'Убрать фото': 'Remove photo',
  'Имя': 'Name',
  'Как тебя называть?': 'What should we call you?',
  'Необязательно': 'Optional',
  'Проверь формат email': 'Check the email format',
  'Email не указан': 'Email not specified',
  'Профиль сохранён': 'Profile saved',
  'Редактировать профиль': 'Edit profile',
  'Твой кинодневник': 'Your film diary',
  'ЛИЧНЫЙ КИНОДНЕВНИК': 'PERSONAL FILM DIARY',
  'Твоя история в кино': 'Your story in cinema',
  'Фильмы, к которым ты возвращаешься, и те, что ещё впереди.':
      'Films you return to, and the ones still ahead.',
  'Из твоего дневника': 'From your diary',
  'Здесь будут твои впечатления': 'Your impressions will appear here',
  'Открой фильм и сохрани первую оценку или отзыв.':
      'Open a film and save your first rating or review.',
  'Это локальный профиль. Вход в аккаунт пока не подключён.':
      'This is a local profile. Account sign-in is not connected yet.',
  'Твой комфортный просмотр': 'Make yourself at home',
  'Настрой оформление и язык приложения.':
      'Choose the look and language of your app.',
  'Следовать настройкам устройства': 'Follow device settings',
  'Фото должно быть не больше 5 МБ.': 'The photo must be no larger than 5 MB.',
  'Не удалось прочитать фото.': 'Could not read the photo.',
  'Не удалось выбрать фото. Попробуй ещё раз.':
      'Could not choose the photo. Please try again.',
  'JPG, PNG или WebP · до 5 МБ': 'JPG, PNG or WebP · up to 5 MB',
  'Мой кинодневник': 'My film diary',
  'Моя оценка': 'My rating',
  'Мои впечатления': 'My impressions',
  'Что ты думаешь об этом фильме?': 'What do you think about this film?',
  'Убрать оценку': 'Clear rating',
  'Есть несохранённые изменения': 'Unsaved changes',
  'Сохраняем…': 'Saving…',
  'Сохранено': 'Saved',
  'Сохранить изменения перед выходом?': 'Save changes before leaving?',
  'Остаться': 'Stay',
  'Выйти без сохранения': 'Leave without saving',
  'Сохранить и выйти': 'Save and leave',
  'Сохранённые результаты поиска.': 'Saved search results.',
  'Сохранённые сведения о фильме.': 'Saved movie details.',
  'мин': 'min',
  'Описание пока недоступно.': 'Description unavailable.',
  'Описание отсутствует.': 'Description unavailable.',
  'Не настроен доступ TMDB. Проверьте локальный файл .vscode/tmdb.local.json.':
      'TMDB is not configured. Check the local .vscode/tmdb.local.json file.',
  'TMDB отклонил доступ. Проверьте API-ключ.':
      'TMDB rejected access. Check the API key.',
  'Слишком много запросов. Попробуйте позже.': 'Too many requests. Try later.',
  'Сервис не ответил вовремя. Попробуйте ещё раз.':
      'The service timed out. Try again.',
  'Не удалось подключиться. Проверьте интернет и доступность сервиса.': 'Connection failed. Check your internet connection and service availability.',
  'Сервис вернул некорректные данные.': 'The service returned invalid data.',
  'Сервис вернул некорректные сведения о фильмах.':
      'The service returned invalid movie data.',
  'Сервис вернул некорректные сведения о фильме.':
      'The service returned invalid movie details.',
  'Нет просмотренных фильмов.': 'No watched movies yet.',
  'Нет избранных фильмов.': 'No favorite movies yet.',
  'Главная': 'Home',
  'На главную': 'Go to Home',
  'Firebase Auth не разрешает домен этой страницы. Открой локальную версию по адресу http://localhost:8765 вместо 127.0.0.1. Для другого адреса добавь домен в Authentication → Settings → Authorized domains.':
      'Firebase Auth does not allow this page’s domain. For local use, open http://localhost:8765 instead of 127.0.0.1. For another address, add its domain under Authentication → Settings → Authorized domains.',
  'Браузер заблокировал окно Google. Разреши всплывающие окна и повтори попытку.':
      'The browser blocked the Google window. Allow pop-ups for this site and try again.',
  'Вход через Google отменён до завершения.':
      'Google sign-in was cancelled before it completed.',
  'Поиск': 'Search',
  'Коллекция': 'My collection',
  'Отзывы': 'Reviews',
  'Профиль': 'Profile',
  'Настройки': 'Settings',
  'Моя коллекция': 'My collection',
  'Твой личный кинодневник': 'Your personal movie diary',
  'Хочу посмотреть': 'Watchlist',
  'Просмотрено': 'Watched',
  'Избранное': 'Favorites',
  'Пока нет фильмов. Добавь фильм на его странице.':
      'No movies yet. Add one from its details page.',
  'Удалить из списка': 'Remove from watchlist',
  'В список просмотра': 'Add to watchlist',
  'О фильме': 'About the movie',
  'Отметить просмотренным': 'Mark as watched',
  'Оценить и написать отзыв': 'Rate and write a review',
  'Постер пока недоступен': 'Poster unavailable',
  'Добавить в избранное': 'Add to favorites',
  'Убрать из избранного': 'Remove from favorites',
  'Убрать отметку просмотра': 'Mark as unwatched',
  'Сохранить': 'Save',
  'Отмена': 'Cancel',
  'Личный отзыв': 'Personal review',
  'Оценка': 'Rating',
  'Без оценки': 'No rating',
  'Мои отзывы': 'My reviews',
  'Пока нет отзывов и оценок.': 'No reviews or ratings yet.',
  'Тема': 'Theme',
  'Тёмная': 'Dark',
  'Светлая': 'Light',
  'Системная': 'System',
  'Язык': 'Language',
  'Данные сохраняются на этом устройстве.': 'Data is saved on this device.',
  'Поиск фильмов': 'Search movies',
  'Название фильма': 'Movie title',
  'Очистить': 'Clear',
  'Введи название фильма для поиска в TMDB.':
      'Enter a movie title to search TMDB.',
  'Ничего не найдено. Попробуй другое название.':
      'No results. Try another title.',
  'Каталог пока пуст.': 'The catalog is empty.',
  'Повторить': 'Retry',
  'Твоё следующее\nкиновпечатление.': 'Your next\nmovie experience.',
  'Находи фильмы. Сохраняй моменты.': 'Discover movies. Keep the moments.',
  'Выбрали для тебя': 'Selected for you',
  'ПОДБОРКА': 'DISCOVER',
  'Твоя киноистория начинается здесь': 'Your movie story starts here',
  'Добавляй фильмы в список просмотра, ставь оценки и сохраняй свои впечатления.':
      'Save movies to your watchlist, rate them and record your impressions.',
  'Мой список просмотра': 'My watchlist',
  'Данные: TMDB. Приложение использует TMDB API и не одобрено или сертифицировано TMDB.': 'Data: TMDB. This product uses the TMDB API but is not endorsed or certified by TMDB.',
  'Год неизвестен': 'Year unknown',
  'Жанры не указаны': 'Genres not specified',
  'Нет обновления из сети. Показан сохранённый каталог.':
      'Network update unavailable. Showing saved catalog.',
  'Сохранённый каталог · обновляем из сети':
      'Saved catalog · updating from network',
  'Не удалось сохранить. Попробуй ещё раз.':
      'Could not save. Please try again.',
};
