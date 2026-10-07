/// Registro das operações de tratamento do Faça a Festa (art. 37 da LGPD).
///
/// Cada item liga a tela real do aplicativo aos campos pessoais, à finalidade,
/// à base legal do art. 7 e à proteção já aplicada.
class TratamentoDados {
  const TratamentoDados({
    required this.modulo,
    required this.tela,
    required this.campos,
    required this.titulares,
    required this.finalidade,
    required this.baseLegal,
    required this.protecao,
    required this.retencao,
    required this.compartilhamento,
  });

  final String modulo;
  final String tela;
  final List<String> campos;
  final String titulares;
  final String finalidade;
  final String baseLegal;
  final String protecao;
  final String retencao;
  final String compartilhamento;
}

abstract final class RegistroTratamento {
  static const List<TratamentoDados> itens = [
    TratamentoDados(
      modulo: 'Conta e autenticação',
      tela: 'Cadastro e login',
      campos: [
        'Nome',
        'E-mail',
        'Senha',
        'Data e versão do aceite da política',
      ],
      titulares: 'Organizador, fornecedor e convidado com conta',
      finalidade:
          'Criar a conta, autenticar o acesso e comprovar o aceite da política.',
      baseLegal:
          'Execução de contrato (art. 7º, V) e consentimento do aceite (art. 7º, I).',
      protecao:
          'A senha fica no Firebase Authentication, não no aplicativo. O cadastro só segue com o aceite marcado.',
      retencao: 'Enquanto a conta estiver ativa e pelo prazo legal de segurança.',
      compartilhamento: 'Google Firebase Authentication.',
    ),
    TratamentoDados(
      modulo: 'Conta e autenticação',
      tela: 'Entrada com Google',
      campos: ['Identificador da conta Google', 'Nome público', 'Foto pública'],
      titulares: 'Quem escolhe entrar com Google',
      finalidade: 'Autenticar sem criar uma senha própria do aplicativo.',
      baseLegal: 'Consentimento ao escolher o provedor (art. 7º, I).',
      protecao: 'O aplicativo recebe só o perfil público autorizado pelo Google.',
      retencao: 'Enquanto a conta estiver vinculada.',
      compartilhamento: 'Google Identity / Firebase Authentication.',
    ),
    TratamentoDados(
      modulo: 'Conta e autenticação',
      tela: 'Verificação em duas etapas',
      campos: ['Segredo TOTP', 'Confirmação por e-mail'],
      titulares: 'Usuário que ativa a verificação',
      finalidade: 'Reduzir acesso indevido à conta.',
      baseLegal:
          'Legítimo interesse de segurança e execução de contrato (art. 7º, IX e V).',
      protecao: 'O segredo fica na conta autenticada, fora das telas de terceiros.',
      retencao: 'Enquanto a verificação estiver ativa.',
      compartilhamento: 'Firebase Authentication.',
    ),
    TratamentoDados(
      modulo: 'Perfil',
      tela: 'Meu perfil',
      campos: ['Nome', 'Foto', 'Telefone', 'CPF quando informado'],
      titulares: 'Usuário da conta',
      finalidade: 'Identificar o titular e permitir correção dos dados.',
      baseLegal: 'Execução de contrato (art. 7º, V).',
      protecao: 'A correção é feita pelo próprio titular na tela Meu perfil.',
      retencao: 'Enquanto a conta estiver ativa.',
      compartilhamento: 'Firestore, apenas no documento do próprio usuário.',
    ),
    TratamentoDados(
      modulo: 'Endereço e localização',
      tela: 'Endereço do usuário e do evento',
      campos: [
        'CEP',
        'Logradouro',
        'Número',
        'Complemento',
        'Bairro',
        'Cidade',
        'UF',
      ],
      titulares: 'Organizador e fornecedor',
      finalidade:
          'Definir o local da festa e o endereço de cadastro. O match de fornecedores usa só cidade e região.',
      baseLegal: 'Execução de contrato (art. 7º, V).',
      protecao:
          'O endereço completo permanece com o organizador. A consulta de CEP passa pela function buscarCepGoogle, na região southamerica-east1, com cache.',
      retencao: 'Enquanto o cadastro ou o evento existir.',
      compartilhamento:
          'Cloud Function de CEP e, quando necessário, o serviço de geocodificação usado por ela.',
    ),
    TratamentoDados(
      modulo: 'Endereço e localização',
      tela: 'Localização do aparelho e território do fornecedor',
      campos: [
        'Latitude e longitude em primeiro plano',
        'Raio de atendimento',
        'Regiões atendidas',
      ],
      titulares: 'Fornecedor e organizador que autoriza a localização',
      finalidade:
          'Sugerir fornecedores próximos e desenhar a área de atendimento.',
      baseLegal: 'Consentimento da permissão do sistema (art. 7º, I).',
      protecao:
          'Não há rastreamento em segundo plano. Sem a permissão, a busca segue sem coordenada.',
      retencao: 'Enquanto o território estiver cadastrado.',
      compartilhamento: 'Firestore do território do fornecedor.',
    ),
    TratamentoDados(
      modulo: 'Evento',
      tela: 'Cadastro da festa',
      campos: [
        'Nome e data da festa',
        'Horário e local',
        'Descrição e mensagem aos convidados',
        'Nomes de noivos, aniversariante, gestante, bebê ou responsável',
        'Idade, quando informada',
        'Totais de adultos, crianças e bebês',
        'Capa e texto do banner',
      ],
      titulares: 'Organizador e pessoas nomeadas na festa, inclusive crianças',
      finalidade: 'Planejar o evento e exibir o convite a quem foi convidado.',
      baseLegal:
          'Execução de contrato (art. 7º, V). Dados de criança seguem o art. 14, informados pelo responsável.',
      protecao:
          'Convidados veem o necessário para o convite. Fornecedores não recebem a ficha inteira da festa.',
      retencao: 'Enquanto o evento não for excluído pelo organizador.',
      compartilhamento:
          'Firestore e Storage da capa. Convidados do mesmo evento veem os dados do convite.',
    ),
    TratamentoDados(
      modulo: 'Convidados',
      tela: 'Lista, grupos, mesas e RSVP',
      campos: [
        'Nome',
        'Telefone',
        'E-mail',
        'Confirmação de presença',
        'Tipo (adulto, criança ou bebê)',
        'Grupo familiar',
        'Mesa',
        'Cuidado especial',
        'Token do convite',
      ],
      titulares: 'Convidados inseridos pelo organizador, inclusive crianças e bebês',
      finalidade:
          'Montar a lista, enviar o convite e contar lugares e buffet.',
      baseLegal:
          'Execução de contrato com o organizador (art. 7º, V). Criança e bebê: art. 14, só o primeiro nome, sem documento.',
      protecao:
          'O convite avisa a finalidade. Criança e bebê exibem o aviso do art. 14. A lista pode ser exportada em CSV e cada convidado pode ser excluído.',
      retencao: 'Enquanto o convidado permanecer no evento.',
      compartilhamento:
          'O próprio convidado, ao abrir o link. Fornecedores não recebem a lista.',
    ),
    TratamentoDados(
      modulo: 'Convidados',
      tela: 'Importar da agenda',
      campos: ['Nome e telefone escolhidos na agenda do aparelho'],
      titulares: 'Contatos que o organizador seleciona',
      finalidade: 'Evitar redigitar o convite.',
      baseLegal: 'Consentimento da permissão de contatos (art. 7º, I).',
      protecao: 'A agenda inteira não é enviada para marketing nem para terceiros.',
      retencao: 'Só os contatos que o organizador confirmar na lista do evento.',
      compartilhamento: 'Nenhum, além do que passar a constar na lista do evento.',
    ),
    TratamentoDados(
      modulo: 'Convidados',
      tela: 'Área do convidado',
      campos: ['Nome', 'Status de presença', 'Tarefas atribuídas', 'Dados do evento do convite'],
      titulares: 'Convidado que abre o link',
      finalidade: 'Confirmar presença, ver a festa e as tarefas daquele convite.',
      baseLegal: 'Execução do convite solicitado pelo organizador (art. 7º, V).',
      protecao:
          'Ao abrir o link, o convidado vê para que os dados são usados e a política.',
      retencao: 'Enquanto o convite existir.',
      compartilhamento: 'Organizador do evento.',
    ),
    TratamentoDados(
      modulo: 'Festa',
      tela: 'Presentes e contribuições',
      campos: ['Item de presente', 'Quem reservou ou contribuiu', 'Valor, quando informado'],
      titulares: 'Organizador e convidado que interage com a lista',
      finalidade: 'Coordenar a lista de presentes da festa.',
      baseLegal: 'Execução de contrato (art. 7º, V).',
      protecao:
          'Há cópia local em SQLite/Drift para uso offline. Essa cópia ainda não é criptografada em disco.',
      retencao: 'Na nuvem, enquanto o evento existir. No aparelho, até limpar ou desinstalar o app.',
      compartilhamento: 'Firestore e banco local do aparelho.',
    ),
    TratamentoDados(
      modulo: 'Festa',
      tela: 'Cardápio, tarefas e calculadora',
      campos: [
        'Itens de cardápio',
        'Tarefa e convidado responsável',
        'Quantidade de adultos, crianças e bebês usada na estimativa',
      ],
      titulares: 'Organizador e convidado marcado como responsável',
      finalidade: 'Organizar a festa e estimar consumo.',
      baseLegal: 'Execução de contrato (art. 7º, V).',
      protecao: 'A tarefa mostra só o responsável daquele item.',
      retencao: 'Enquanto o evento existir.',
      compartilhamento: 'Firestore. A calculadora pode enviar tipo, cidade e quantidades à sugestão do evento, sem uso publicitário.',
    ),
    TratamentoDados(
      modulo: 'Financeiro',
      tela: 'Orçamento do organizador',
      campos: [
        'Custo estimado e realizado',
        'Categoria',
        'Status',
        'Anotações',
      ],
      titulares: 'Organizador',
      finalidade: 'Controlar os gastos da festa.',
      baseLegal: 'Execução de contrato (art. 7º, V).',
      protecao:
          'A tela informa que só o organizador vê o total. O fornecedor não recebe o orçamento global.',
      retencao: 'Enquanto o evento existir.',
      compartilhamento: 'Firestore, restrito ao organizador do evento.',
    ),
    TratamentoDados(
      modulo: 'Financeiro',
      tela: 'Cotação do fornecedor',
      campos: [
        'Serviço pedido',
        'Valor e prazo da proposta',
        'Status',
        'Contato ligado àquela cotação',
      ],
      titulares: 'Organizador solicitante e fornecedor da cotação',
      finalidade: 'Negociar um serviço específico.',
      baseLegal: 'Execução de procedimentos preliminares e de contrato (art. 7º, V).',
      protecao:
          'O fornecedor vê o aviso de acesso restrito: apenas a cotação dele.',
      retencao: 'Enquanto a cotação ou o evento existir.',
      compartilhamento: 'Organizador e o fornecedor daquela cotação.',
    ),
    TratamentoDados(
      modulo: 'Comunicação',
      tela: 'Chat da cotação',
      campos: ['Texto da mensagem', 'Nome de quem enviou', 'Data e leitura'],
      titulares: 'Organizador e fornecedor da conversa',
      finalidade: 'Tratar a proposta daquele serviço.',
      baseLegal: 'Execução de contrato (art. 7º, V).',
      protecao:
          'A conversa fica ligada à cotação. Não há publicação da mensagem para outros usuários.',
      retencao: 'Enquanto a cotação existir.',
      compartilhamento: 'Somente os dois participantes da cotação.',
    ),
    TratamentoDados(
      modulo: 'Comunicação',
      tela: 'Avaliações',
      campos: ['Nome de quem avaliou', 'Nota', 'Comentário', 'Evento'],
      titulares: 'Organizador que avalia e fornecedor avaliado',
      finalidade: 'Registrar a experiência do serviço contratado.',
      baseLegal: 'Execução de contrato e legítimo interesse de reputação (art. 7º, V e IX).',
      protecao: 'A avaliação fica associada ao serviço, não à lista de convidados.',
      retencao: 'Enquanto o perfil do fornecedor exibir a avaliação.',
      compartilhamento: 'Visitantes do perfil público do fornecedor veem nota e comentário.',
    ),
    TratamentoDados(
      modulo: 'Comunicação',
      tela: 'Avisos por push',
      campos: [
        'Token do aparelho',
        'Preferência de convites',
        'Preferência de cotações',
        'Preferência de chat',
      ],
      titulares: 'Usuário que autoriza notificações',
      finalidade: 'Registrar o token e a preferência de cada tipo de aviso.',
      baseLegal: 'Consentimento (art. 7º, I), revogável na tela Avisos.',
      protecao:
          'A preferência fica na conta. O envio de convite por e-mail e de avaliação por push consulta esse desligamento. Recusar a permissão do sistema impede o token.',
      retencao: 'Token enquanto a permissão existir. Preferências ficam salvas no aparelho.',
      compartilhamento: 'Firebase Cloud Messaging.',
    ),
    TratamentoDados(
      modulo: 'Fornecedor',
      tela: 'Cadastro comercial e portfólio',
      campos: [
        'Razão social',
        'CNPJ',
        'Telefone',
        'E-mail',
        'Descrição',
        'Categorias e tipos de festa',
        'Banner e fotos do serviço',
      ],
      titulares: 'Fornecedor',
      finalidade: 'Publicar a oferta e receber cotações.',
      baseLegal: 'Execução de contrato (art. 7º, V). CNPJ é dado cadastral da atividade.',
      protecao:
          'O upload de imagem exige declaração de direito de imagem. O perfil público mostra só o que foi publicado no catálogo.',
      retencao: 'Enquanto o cadastro do fornecedor estiver ativo.',
      compartilhamento:
          'Organizadores que buscam o catálogo veem os dados publicados.',
    ),
    TratamentoDados(
      modulo: 'Imagens',
      tela: 'Capa do evento, referências e inspirações',
      campos: ['Arquivo de imagem', 'Texto associado', 'Pessoas que aparecem na foto'],
      titulares: 'Quem envia a foto e as pessoas retratadas',
      finalidade: 'Ilustrar a festa, o portfólio ou a referência visual.',
      baseLegal: 'Consentimento do envio e declaração de autorização de imagem (art. 7º, I).',
      protecao: 'Sem a declaração, a galeria não abre e o arquivo não é enviado.',
      retencao: 'Enquanto a imagem permanecer no evento, na referência ou no portfólio.',
      compartilhamento: 'Firebase Storage. Quem tem acesso àquela tela vê a imagem.',
    ),
    TratamentoDados(
      modulo: 'Comunidade',
      tela: 'Publicações e comentários',
      campos: ['Nome do autor', 'Texto', 'Imagem', 'Comentário', 'Curtidas'],
      titulares: 'Usuário que publica',
      finalidade: 'Troca entre usuários na área de comunidade.',
      baseLegal: 'Consentimento ao publicar (art. 7º, I).',
      protecao: 'O autor é o nome da conta. A exclusão da conta alcança esse conteúdo mediante solicitação.',
      retencao: 'Enquanto a publicação não for removida.',
      compartilhamento: 'Demais usuários com acesso à comunidade.',
    ),
    TratamentoDados(
      modulo: 'Segurança',
      tela: 'Auditoria',
      campos: [
        'Quem fez a ação',
        'E-mail do ator',
        'Resumo da alteração',
        'Hash de integridade',
      ],
      titulares: 'Usuário que executa uma operação auditada',
      finalidade: 'Apurar abuso, falha e responsabilidade sobre alterações.',
      baseLegal:
          'Legítimo interesse de segurança e obrigação de prestação de contas (art. 7º, IX, e art. 6º, X).',
      protecao:
          'O fornecedor só vê registros marcados como visíveis para ele. O administrador vê o painel completo.',
      retencao:
          '365 dias. Uma rotina diária apaga os logs de auditoria mais antigos que esse prazo.',
      compartilhamento: 'Firestore de auditoria, conforme o papel.',
    ),
    TratamentoDados(
      modulo: 'Conta e autenticação',
      tela: 'Pedidos do titular',
      campos: ['Tipo do pedido', 'Resumo', 'Protocolo', 'Data', 'Status'],
      titulares: 'Usuário autenticado que exerce um direito',
      finalidade:
          'Registrar acesso, correção, exclusão, anonimização, oposição ou revogação (art. 18).',
      baseLegal: 'Obrigação legal de atender o titular (art. 18).',
      protecao:
          'Só o próprio titular cria o pedido. O administrador atende na fila Protocolos LGPD. A exclusão só apaga a conta quando o administrador executa o protocolo.',
      retencao: 'Pelo prazo necessário para comprovar o atendimento do pedido.',
      compartilhamento: 'Firestore, no documento do próprio usuário, e administradores.',
    ),
    TratamentoDados(
      modulo: 'Administração',
      tela: 'Painel administrativo',
      campos: ['Nome', 'E-mail', 'Tipo de conta', 'Status ativo', 'Cidade e UF'],
      titulares: 'Todos os usuários cadastrados',
      finalidade: 'Operar o aplicativo, ativar contas e atender solicitações.',
      baseLegal: 'Execução de contrato e legítimo interesse (art. 7º, V e IX).',
      protecao: 'A rota exige perfil de administrador.',
      retencao: 'Enquanto a conta existir.',
      compartilhamento: 'Somente administradores do aplicativo.',
    ),
  ];

  static List<String> get modulos {
    final nomes = <String>[];
    for (final item in itens) {
      if (!nomes.contains(item.modulo)) nomes.add(item.modulo);
    }
    return nomes;
  }

  static List<TratamentoDados> doModulo(String modulo) {
    return itens.where((item) => item.modulo == modulo).toList();
  }

  static List<TratamentoDados> buscar(String consulta) {
    final termo = consulta.trim().toLowerCase();
    if (termo.isEmpty) return itens;
    return itens.where((item) {
      final texto = [
        item.modulo,
        item.tela,
        item.titulares,
        item.finalidade,
        item.baseLegal,
        item.protecao,
        item.retencao,
        item.compartilhamento,
        ...item.campos,
      ].join(' ').toLowerCase();
      return texto.contains(termo);
    }).toList();
  }
}
