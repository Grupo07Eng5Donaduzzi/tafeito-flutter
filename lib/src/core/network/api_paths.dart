class ApiPaths {
  const ApiPaths._();

  static const mainBaseUrl = String.fromEnvironment(
    'TAFEITO_MAIN_API_BASE_URL',
    defaultValue: 'https://tafeito.rietto.com/main',
  );
  static const chatBaseUrl = String.fromEnvironment(
    'TAFEITO_CHAT_API_BASE_URL',
    defaultValue: 'https://tafeito.rietto.com/chat',
  );
  static const paymentsBaseUrl = String.fromEnvironment(
    'TAFEITO_PAYMENTS_API_BASE_URL',
    defaultValue: 'https://tafeito.rietto.com/payments',
  );

  static const authRegister = '/v1/auth/register';
  static const authLogin = '/v1/auth/login';
  static const becomeProvider = '/v1/auth/becomeProvider';

  static const passwordRecoveryRequest = '/v1/auth/forgot-password';
  static const passwordRecoveryVerify = '/auth/password-recovery/verify';
  static const passwordRecoveryReset = '/auth/password-recovery/reset';

  static const services = '/v1/services';
  static const servicesMine = '/v1/services/mine';
  static const serviceCategories = '/v1/services/categories';
  static String service(String id) => '/v1/services/$id';
  static String servicePhoto(String id) => '/v1/services/$id/photo';

  static const budgetRequests = '/v1/budgetRequests';
  static const myBudgetRequests = '/v1/budgetRequests/mine';
  static const availableBudgetRequests = '/v1/budgetRequests/available';
  static String budgetRequest(String id) => '/v1/budgetRequests/$id';
  static String budgetRequestPhotos(String id) =>
      '/v1/budgetRequests/$id/photos';
  static String cancelBudgetRequest(String id) =>
      '/v1/budgetRequests/$id/cancel';
  static String declineBudgetRequest(String id) =>
      '/v1/budgetRequests/$id/providerDecline';

  static const proposals = '/v1/proposals';
  static const providerProposals = '/v1/proposals/provider/created';
  static const clientProposals = '/v1/proposals/client/requested';
  static const clientProposalHistory = '/v1/proposals/client/history';
  static const providerProposalHistory = '/v1/proposals/provider/history';
  static String proposal(String id) => '/v1/proposals/$id';
  static String acceptProposal(String id) => '/v1/proposals/$id/accept';
  static String rejectProposal(String id) => '/v1/proposals/$id/reject';
  static String contestProposal(String id) => '/v1/proposals/$id/contest';
  static String proposalPayment(String id) => '/v1/proposals/$id/payment';
  static String providerConfirmProposal(String id) =>
      '/v1/proposals/$id/providerConfirm';
  static String clientConfirmProposal(String id) =>
      '/v1/proposals/$id/clientConfirm';
  static String proposalInvoice(String id) => '/v1/proposals/$id/invoice';

  static String reviseProposal(String id) => '/v1/proposals/$id/revise';
  static String negotiatingProposals(String clientId) =>
      '/v1/proposals/negotiating-with/$clientId';

  static String serviceReviews(String serviceId) =>
      '/v1/reviews/services/$serviceId';
  static String serviceReviewSummary(String serviceId) =>
      '/v1/reviews/services/$serviceId/summary';

  static const me = '/v1/users/me';
  static const myAvatar = '/v1/users/me/avatar';
  static String user(String id) => '/v1/users/$id';
}

class ChatApiPaths {
  const ChatApiPaths._();

  static const messages = '/v1/chat/messages';
  static String message(String id) => '/v1/chat/messages/$id';
  static String markRead(String id) => '/v1/chat/messages/$id/read';
  static String markDelivered(String id) => '/v1/chat/messages/$id/delivered';
  static String conversation(String id) => '/v1/chat/conversations/$id';
  static String conversationMessages(String conversationId) =>
      '/v1/chat/conversations/$conversationId/messages';
  static String serviceMessages(String serviceId) =>
      '/v1/chat/services/$serviceId/messages';
  static String userMessages(String userId) =>
      '/v1/chat/users/$userId/messages';
  static const conversations = '/v1/chat/conversations';
  static const ensureConversation = '/v1/chat/conversations/ensure';
}

class PaymentsApiPaths {
  const PaymentsApiPaths._();

  static const pix = '/v1/payments/pix';
  static String status(String id) => '/v1/payments/$id/status';
}
