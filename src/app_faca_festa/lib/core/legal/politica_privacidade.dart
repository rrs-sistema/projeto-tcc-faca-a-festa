/// Texto da política de privacidade exibido no app e alinhado à página pública.
abstract final class PoliticaPrivacidade {
  static const String urlPublica =
      'https://faca-a-festa.web.app/privacidade.html';

  static const String versao = '2026-10-06';

  static const String atualizacao = '6 de outubro de 2026';

  static const String introducao =
      'O Faça a Festa (“nós”, “aplicativo”) é um serviço de planejamento de '
      'eventos que conecta organizadores, convidados e fornecedores. Esta '
      'política descreve quais dados pessoais tratamos, para que finalidade e '
      'com quem são compartilhados, em conformidade com a Lei Geral de '
      'Proteção de Dados (Lei nº 13.709/2018 — LGPD).';

  static const List<PoliticaSecao> secoes = [
    PoliticaSecao(
      titulo: '1. Quem é o controlador',
      corpo:
          'O controlador dos dados é o responsável pelo aplicativo Faça a Festa. '
          'Pedidos de acesso, correção ou exclusão podem ser feitos pelo e-mail '
          'de suporte informado na ficha do aplicativo na Google Play Store ou '
          'pelo próprio aplicativo, na área da conta.',
    ),
    PoliticaSecao(
      titulo: '2. Dados que coletamos',
      corpo:
          'Conta e perfil: nome, e-mail, senha (armazenada de forma criptografada '
          'pelo Firebase Authentication) e, se você entrar com Google, o '
          'identificador da conta Google, nome e foto públicos.\n\n'
          'Perfil opcional: foto, telefone e endereço.\n\n'
          'Eventos: informações que você cadastra sobre a festa (data, local, '
          'orçamento, checklist, cardápio, lista de presentes e convites).\n\n'
          'Convidados: nome, contato, confirmação de presença e, quando o '
          'organizador informa, o tipo (adulto, criança ou bebê) e o grupo '
          'familiar.\n\n'
          'Fornecedores: dados comerciais como nome fantasia, categorias de '
          'serviço, área de atendimento, fotos do portfólio e, quando '
          'informado, CNPJ.\n\n'
          'Localização: apenas em primeiro plano, quando você autoriza, para '
          'sugerir fornecedores próximos e definir território de atendimento. '
          'O match de fornecedores usa cidade e região. O endereço completo '
          'fica com o organizador do evento. Não rastreamos localização em '
          'segundo plano.\n\n'
          'Contatos do aparelho: apenas se você autorizar, para facilitar o '
          'convite de convidados. Não enviamos sua agenda a terceiros para '
          'marketing.\n\n'
          'Mídia: fotos que você escolhe na galeria (capa do evento, perfil, '
          'referências ou portfólio), enviadas ao Firebase Storage. O envio '
          'exige a declaração de que há autorização das pessoas que aparecem '
          'na imagem.\n\n'
          'Notificações: token do dispositivo para enviar avisos sobre cotações, '
          'convites e chat, se você permitir. Na conta, dá para desligar cada '
          'tipo de aviso.\n\n'
          'Dados técnicos: identificadores de sessão, registros de auditoria de '
          'operações relevantes e diagnóstico de falhas necessários para '
          'segurança e funcionamento.',
    ),
    PoliticaSecao(
      titulo: '3. Para que usamos os dados',
      corpo:
          'Criar e autenticar sua conta; permitir o planejamento do evento; '
          'conectar organizadores e fornecedores; enviar convites; processar '
          'cotações e orçamentos; exibir o perfil público do fornecedor a '
          'quem busca serviços; enviar notificações que você autorizou; '
          'prevenir fraude e abuso; e cumprir obrigações legais.',
    ),
    PoliticaSecao(
      titulo: '4. Compartilhamento',
      corpo:
          'Usamos Google Firebase (Authentication, Firestore, Storage, Cloud '
          'Functions, Cloud Messaging e App Check) e, quando necessário, '
          'serviços de geocodificação/CEP para completar endereços. Esses '
          'operadores tratam dados em nome do aplicativo.\n\n'
          'Outros usuários vêem apenas o que é necessário ao fluxo: '
          'organizadores vêem dados do fornecedor publicados no catálogo; '
          'fornecedores vêem solicitações e dados de contato ligados à cotação; '
          'convidados vêem informações do evento para o qual foram convidados.\n\n'
          'Não vendemos dados pessoais e não usamos identificador de '
          'publicidade para anúncios.',
    ),
    PoliticaSecao(
      titulo: '5. Permissões do Android',
      corpo:
          'Internet: funcionamento online do aplicativo.\n'
          'Localização aproximada/precisa (em primeiro plano): busca de '
          'fornecedores e território de atendimento.\n'
          'Contatos: importar convidados, só com sua autorização.\n'
          'Notificações: avisos sobre o evento, cotações e avaliações.\n\n'
          'Fotos são escolhidas pelo seletor do sistema, sem acesso amplo à '
          'galeria. Não solicitamos câmera nem localização em segundo plano.',
    ),
    PoliticaSecao(
      titulo: '6. Retenção e exclusão',
      corpo:
          'Mantemos os dados enquanto a conta estiver ativa e pelo prazo '
          'necessário às obrigações legais e à segurança (por exemplo, '
          'registros de auditoria). Em Dados protegidos você solicita a exclusão, '
          'a anonimização, o bloqueio ou a oposição. O pedido gera um protocolo. '
          'A exclusão da conta é executada pelo administrador na fila de '
          'protocolos. Logs de auditoria são mantidos por 365 dias.',
    ),
    PoliticaSecao(
      titulo: '7. Seus direitos (LGPD)',
      corpo:
          'Você pode solicitar confirmação do tratamento, acesso, correção, '
          'anonimização, portabilidade, informação sobre compartilhamentos e '
          'eliminação dos dados pessoais, além de revogar consentimentos. '
          'Também pode petição à Autoridade Nacional de Proteção de Dados '
          '(ANPD).',
    ),
    PoliticaSecao(
      titulo: '8. Crianças e adolescentes',
      corpo:
          'O cadastro no aplicativo é feito por adultos (organizadores e '
          'fornecedores). O organizador pode incluir crianças e bebês na lista '
          'de convidados, apenas com o primeiro nome, para contar lugares e '
          'buffet. Não pedimos documento, foto nem contato próprio da criança. '
          'Quem insere esses dados declara ser o responsável, e o tratamento '
          'segue o art. 14 da LGPD. Ao abrir o convite digital, o convidado é '
          'informado de que nome, contato e confirmação de presença são usados '
          'somente naquele evento.',
    ),
    PoliticaSecao(
      titulo: '9. Segurança',
      corpo:
          'Adotamos autenticação, regras de acesso no Firestore/Storage e '
          'comunicação criptografada (HTTPS). Nenhum sistema é 100% seguro; '
          'recomendamos senha exclusiva e, quando disponível, verificação em '
          'duas etapas.',
    ),
    PoliticaSecao(
      titulo: '10. Alterações',
      corpo:
          'Esta política pode ser atualizada para refletir mudanças no '
          'aplicativo ou na legislação. A data de atualização consta no topo '
          'desta página. O uso continuado após a publicação indica ciência da '
          'versão vigente.',
    ),
    PoliticaSecao(
      titulo: '11. Registro das operações',
      corpo:
          'O detalhamento de cada tela, dos campos tratados, da finalidade, '
          'da base legal e da proteção está no aplicativo, em Dados protegidos, '
          'na área da conta e também a partir desta política. Ali o titular '
          'pode exportar o dossiê, corrigir o cadastro, revogar avisos, pedir '
          'anonimização ou bloqueio, registrar oposição e solicitar a exclusão.',
    ),
  ];
}

class PoliticaSecao {
  const PoliticaSecao({required this.titulo, required this.corpo});

  final String titulo;
  final String corpo;
}
