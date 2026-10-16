/// Fora do navegador (testes) só anota o que seria aberto.
final linksAbertos = <String>[];

void abrirLink(String url) => linksAbertos.add(url);
