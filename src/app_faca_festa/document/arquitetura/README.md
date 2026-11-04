# Arquitetura do Faça a Festa

Atualização de 29/10/2026: o inventário abaixo é histórico. A revisão de imports
do código atual identificou dependências adicionais entre apresentação e dados,
GetX em gateways de dados e dependência indireta de Flutter em um serviço de
domínio. Consulte o capítulo 8 da
[documentação consolidada](../tcc/documentacao-software-faca-a-festa.md#8-arquitetura-do-sistema)
para as visões revisadas e os limites observados. As regras de separação deste
acervo não devem ser interpretadas como isolamento integral já verificado no código atual.

Documentação técnica da **Clean Architecture** do cliente Flutter (`lib/`) e de como ele se conecta ao Firebase e às Cloud Functions.

Inventário conferido no código em setembro de 2026. Não descreve um modelo ideal: descreve o que o repositório faz hoje.

| Documento | Conteúdo |
| --- | --- |
| [01 — Camadas e regras](01-camadas-e-regras.md) | Pastas, responsabilidade de cada camada, regras de dependência, o que a arquitetura **não** é |
| [02 — Organogramas](02-organogramas.md) | Diagramas (Mermaid) de camadas, pastas, papéis, composição e sistemas externos |
| [03 — Módulos, bootstrap e fluxos](03-modulos-bootstrap-e-fluxos.md) | Mapa módulo → repositório, raiz de composição GetX, fluxos de sessão e gifts |

Documentação antiga e pontual (módulo de presentes apenas): [`../documentacao_arquitetural.md`](../documentacao_arquitetural.md).
