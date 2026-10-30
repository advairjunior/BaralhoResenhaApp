namespace BaralhoResenhaApp.Api.Dominio;

public sealed partial class Sala
{
    /// <summary>Encerra a noite: todos os celulares vão para os Prêmios da Noite.</summary>
    public void Encerrar(string token)
    {
        lock (_trinco)
        {
            ExigirAnfitriao(token);
            if (Fase == FaseDaSala.Lobby)
                throw new AcaoNaoPermitidaException("A noite nem começou!");
            if (Fase == FaseDaSala.Fim) return;
            Fase = FaseDaSala.Fim;
            TerminouEm = _relogio.GetUtcNow();
            SortearOMico();
            Tocar();
        }
    }

    /// <summary>"Só mais uma": volta ao jogo com uma carta nova, placar mantido.</summary>
    public void Retomar(string token)
    {
        lock (_trinco)
        {
            ExigirAnfitriao(token);
            if (Fase != FaseDaSala.Fim) return;
            TerminouEm = null;
            Mico = null;
            Distribuir();
            Tocar();
        }
    }
}
