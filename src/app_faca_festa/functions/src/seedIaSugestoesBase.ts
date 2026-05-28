import { admin } from "../src/shared/firebaseAdmin";

export type SugestaoBaseSeed = {
  id: string;
  titulo: string;
  descricao: string;
  modulo: string;
  tema: string;
  tipo_evento: string[];
  perfis_festa: string[];
  categoria: string;
  prioridade: 'baixa' | 'media' | 'alta' | 'critica';
  gatilhos: Record<string, unknown>;
  tags: string[];
  ativo: boolean;
  ordem: number;
};

export const sugestoesBaseFestaSeed: SugestaoBaseSeed[] = [
  {
    id: 'calculadora_bebidas_duracao_4h',
    titulo: 'Atenção ao consumo de bebidas',
    descricao: 'Eventos com duração acima de 4 horas tendem a exigir maior atenção ao volume de bebidas, principalmente água, refrigerante e sucos.',
    modulo: 'calculadora',
    tema: 'bebidas',
    tipo_evento: ['todos', 'aniversario', 'aniversario_infantil', 'cha_de_bebe', 'casamento', 'natal', 'ano_novo'],
    perfis_festa: ['economico', 'padrao', 'premium'],
    categoria: 'alerta',
    prioridade: 'alta',
    gatilhos: { duracao_minima_horas: 4, risco_minimo: 40 },
    tags: ['bebidas', 'duracao', 'consumo'],
    ativo: true,
    ordem: 1,
  },
  {
    id: 'calculadora_bolo_convidados_equivalentes',
    titulo: 'Bolo deve acompanhar convidados equivalentes',
    descricao: 'Use os convidados equivalentes como referência para analisar conforto de consumo, evitando estimar bolo apenas pelo número bruto de pessoas.',
    modulo: 'calculadora',
    tema: 'bolo',
    tipo_evento: ['todos', 'aniversario', 'aniversario_infantil', 'cha_de_bebe', 'casamento'],
    perfis_festa: ['economico', 'padrao', 'premium'],
    categoria: 'consumo',
    prioridade: 'media',
    gatilhos: { convidados_equivalentes_minimo: 20 },
    tags: ['bolo', 'convidados_equivalentes'],
    ativo: true,
    ordem: 2,
  },
  {
    id: 'calculadora_salgadinhos_risco_faltar',
    titulo: 'Salgadinhos são item sensível ao risco de falta',
    descricao: 'Quando a festa possui muitos adultos ou longa duração, salgadinhos e comidas salgadas devem receber atenção especial no planejamento.',
    modulo: 'calculadora',
    tema: 'salgadinhos',
    tipo_evento: ['todos', 'aniversario', 'aniversario_infantil', 'cha_de_bebe'],
    perfis_festa: ['economico', 'padrao', 'premium'],
    categoria: 'alerta',
    prioridade: 'alta',
    gatilhos: { risco_minimo: 50, adultos_minimo: 20 },
    tags: ['salgadinhos', 'comidas', 'risco'],
    ativo: true,
    ordem: 3,
  },
  {
    id: 'calculadora_docinhos_criancas',
    titulo: 'Docinhos têm maior saída em festas com crianças',
    descricao: 'Festas com muitas crianças costumam ter consumo maior de docinhos, lembrancinhas e itens de mesa temática.',
    modulo: 'calculadora',
    tema: 'docinhos',
    tipo_evento: ['aniversario_infantil', 'aniversario'],
    perfis_festa: ['economico', 'padrao', 'premium'],
    categoria: 'consumo',
    prioridade: 'media',
    gatilhos: { percentual_criancas_minimo: 30 },
    tags: ['docinhos', 'criancas', 'mesa_tematica'],
    ativo: true,
    ordem: 4,
  },
  {
    id: 'calculadora_lembrancinhas_nao_priorizar_em_orcamento_apertado',
    titulo: 'Lembrancinhas podem ser ajustadas em orçamento apertado',
    descricao: 'Quando o orçamento estiver limitado, lembrancinhas simples ou digitais podem manter a experiência sem comprometer itens essenciais.',
    modulo: 'calculadora',
    tema: 'lembrancinhas',
    tipo_evento: ['todos', 'aniversario_infantil', 'cha_de_bebe', 'casamento'],
    perfis_festa: ['economico', 'padrao'],
    categoria: 'economia',
    prioridade: 'media',
    gatilhos: { economia_minima: 40 },
    tags: ['lembrancinhas', 'economia', 'orcamento'],
    ativo: true,
    ordem: 5,
  },
  {
    id: 'calculadora_orcamento_acima_previsto',
    titulo: 'Orçamento acima do previsto exige priorização',
    descricao: 'Quando o custo estimado ultrapassar o orçamento, priorize alimentos, bebidas e estrutura básica antes de decoração extra ou itens opcionais.',
    modulo: 'calculadora',
    tema: 'orcamento',
    tipo_evento: ['todos'],
    perfis_festa: ['economico', 'padrao', 'premium'],
    categoria: 'financeiro',
    prioridade: 'critica',
    gatilhos: { diferenca_orcamento_maxima: -1 },
    tags: ['orcamento', 'priorizacao', 'custos'],
    ativo: true,
    ordem: 6,
  },
  {
    id: 'calculadora_premium_orcamento_baixo',
    titulo: 'Perfil premium com orçamento baixo precisa de ajuste',
    descricao: 'Se o perfil escolhido for premium e o orçamento estiver baixo, recomende reduzir escopo, negociar fornecedores ou migrar para um perfil padrão.',
    modulo: 'calculadora',
    tema: 'perfil_festa',
    tipo_evento: ['todos'],
    perfis_festa: ['premium'],
    categoria: 'alerta',
    prioridade: 'alta',
    gatilhos: { perfil: 'premium', economia_minima: 50 },
    tags: ['premium', 'orcamento', 'ajuste_de_escopo'],
    ativo: true,
    ordem: 7,
  },
  {
    id: 'calculadora_muitas_criancas',
    titulo: 'Festa com muitas crianças pede cardápio e recreação adequados',
    descricao: 'Quando houver muitas crianças, avalie porções menores, bebidas sem cafeína, recreação, espaço seguro e cardápio simples.',
    modulo: 'calculadora',
    tema: 'criancas',
    tipo_evento: ['aniversario_infantil', 'aniversario', 'cha_de_bebe'],
    perfis_festa: ['economico', 'padrao', 'premium'],
    categoria: 'organizacao',
    prioridade: 'alta',
    gatilhos: { percentual_criancas_minimo: 35 },
    tags: ['criancas', 'cardapio', 'recreacao'],
    ativo: true,
    ordem: 8,
  },
  {
    id: 'calculadora_bebes_conforto',
    titulo: 'Bebês exigem planejamento de conforto',
    descricao: 'Eventos com bebês devem prever espaço tranquilo, trocador, água, facilidade de acesso e horários adequados.',
    modulo: 'calculadora',
    tema: 'bebes',
    tipo_evento: ['cha_de_bebe', 'aniversario_infantil', 'aniversario'],
    perfis_festa: ['economico', 'padrao', 'premium'],
    categoria: 'organizacao',
    prioridade: 'media',
    gatilhos: { bebes_minimo: 1 },
    tags: ['bebes', 'conforto', 'familia'],
    ativo: true,
    ordem: 9,
  },
  {
    id: 'calculadora_duracao_acima_4h',
    titulo: 'Duração acima de 4 horas aumenta consumo geral',
    descricao: 'Festas longas tendem a elevar consumo de bebidas, salgados, descartáveis e necessidade de reposição.',
    modulo: 'calculadora',
    tema: 'duracao',
    tipo_evento: ['todos'],
    perfis_festa: ['economico', 'padrao', 'premium'],
    categoria: 'alerta',
    prioridade: 'alta',
    gatilhos: { duracao_minima_horas: 4 },
    tags: ['duracao', 'consumo', 'reposicao'],
    ativo: true,
    ordem: 10,
  },
  {
    id: 'calculadora_risco_faltar_itens',
    titulo: 'Risco de faltar itens deve virar ação prática',
    descricao: 'Quando o risco de falta for alto, a análise deve indicar quais itens revisar e sugerir margem de segurança sem recalcular quantidades.',
    modulo: 'calculadora',
    tema: 'risco',
    tipo_evento: ['todos'],
    perfis_festa: ['economico', 'padrao', 'premium'],
    categoria: 'alerta',
    prioridade: 'critica',
    gatilhos: { risco_minimo: 70 },
    tags: ['risco', 'itens', 'revisao'],
    ativo: true,
    ordem: 11,
  },
  {
    id: 'calculadora_economia_sem_perder_essencial',
    titulo: 'Economia deve preservar itens essenciais',
    descricao: 'Para economizar, reduza itens decorativos extras, lembrancinhas e personalizações antes de cortar alimentos, bebidas e conforto dos convidados.',
    modulo: 'calculadora',
    tema: 'economia',
    tipo_evento: ['todos'],
    perfis_festa: ['economico', 'padrao'],
    categoria: 'economia',
    prioridade: 'alta',
    gatilhos: { economia_minima: 45 },
    tags: ['economia', 'essencial', 'prioridade'],
    ativo: true,
    ordem: 12,
  },
  {
    id: 'calculadora_fornecedores_antecedencia',
    titulo: 'Fornecedores devem ser acionados com antecedência',
    descricao: 'Itens como bolo, buffet, decoração e recreação dependem de disponibilidade; recomende solicitar orçamento cedo quando houver muitos convidados.',
    modulo: 'calculadora',
    tema: 'fornecedores',
    tipo_evento: ['todos'],
    perfis_festa: ['padrao', 'premium'],
    categoria: 'fornecedor',
    prioridade: 'media',
    gatilhos: { convidados_equivalentes_minimo: 30 },
    tags: ['fornecedores', 'orcamento', 'antecedencia'],
    ativo: true,
    ordem: 13,
  },
  {
    id: 'calculadora_cardapio_equilibrado',
    titulo: 'Cardápio equilibrado melhora a experiência',
    descricao: 'Uma festa confortável combina bebidas, salgados, doces e bolo em equilíbrio, considerando adultos, crianças e duração.',
    modulo: 'calculadora',
    tema: 'cardapio',
    tipo_evento: ['todos'],
    perfis_festa: ['economico', 'padrao', 'premium'],
    categoria: 'cardapio',
    prioridade: 'media',
    gatilhos: {},
    tags: ['cardapio', 'equilibrio', 'experiencia'],
    ativo: true,
    ordem: 14,
  },
  {
    id: 'calculadora_decoracao_priorizar_identidade_visual',
    titulo: 'Decoração deve seguir prioridade visual',
    descricao: 'Para melhorar o impacto sem elevar demais o custo, priorize mesa principal, painel e poucos pontos fotográficos bem definidos.',
    modulo: 'calculadora',
    tema: 'decoracao',
    tipo_evento: ['aniversario', 'aniversario_infantil', 'cha_de_bebe', 'casamento'],
    perfis_festa: ['economico', 'padrao', 'premium'],
    categoria: 'decoracao',
    prioridade: 'baixa',
    gatilhos: {},
    tags: ['decoracao', 'identidade_visual', 'fotos'],
    ativo: true,
    ordem: 15,
  },
];

export async function seedIaSugestoesBase(): Promise<void> {
  if (admin.apps.length === 0) {
    admin.initializeApp();
  }

  const db = admin.firestore();
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (const sugestao of sugestoesBaseFestaSeed) {
    const ref = db.collection('ia_sugestoes_base').doc(sugestao.id);
    batch.set(
      ref,
      {
        ...sugestao,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );
  }

  await batch.commit();
  console.log(`Seed concluído: ${sugestoesBaseFestaSeed.length} sugestões base criadas/atualizadas.`);
}

if (require.main === module) {
  seedIaSugestoesBase()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('Erro ao executar seed ia_sugestoes_base:', error);
      process.exit(1);
    });
}
