namespace BaralhoResenhaApp.Api.Dominio;

public sealed class SalaNaoEncontradaException() : Exception("Sala não encontrada.");

public sealed class JogadorNaoReconhecidoException()
    : Exception("Você não está nesta sala. Entre de novo pelo código.");

/// <summary>Regra do jogo que impede a ação; a mensagem vai direto para a tela.</summary>
public sealed class AcaoNaoPermitidaException(string mensagem) : Exception(mensagem);
